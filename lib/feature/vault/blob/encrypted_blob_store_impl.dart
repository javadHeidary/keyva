import 'dart:io';
import 'dart:typed_data';

import 'package:keyva/core/constants/security_constants.dart';
import 'package:keyva/core/crypto/crypto_service.dart';
import 'package:keyva/core/crypto/encrypted_payload.dart';
import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/core/session/session_service.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';
import 'package:path_provider/path_provider.dart';

class EncryptedBlobStoreImpl implements EncryptedBlobStore {
  EncryptedBlobStoreImpl({
    required CryptoService crypto,
    required SessionService session,
    Future<Directory> Function()? supportDirectory,
  }) : _crypto = crypto,
       _session = session,
       _supportDirectory = supportDirectory;

  static final _blobIdPattern = RegExp(r'^[a-f0-9]{32}$');
  static const _fileVersion = 1;

  final CryptoService _crypto;
  final SessionService _session;
  final Future<Directory> Function()? _supportDirectory;
  final Map<String, Uint8List> _cache = {};

  @override
  Future<Result<String>> write(Uint8List plaintext) async {
    final blobId = _toHex(_crypto.generateSecureBytes(16));
    final written = await writeWithId(blobId: blobId, plaintext: plaintext);
    if (written is FailureResult<void>) {
      return FailureResult(written.failure);
    }
    return Success(blobId);
  }

  @override
  Future<Result<void>> writeWithId({
    required String blobId,
    required Uint8List plaintext,
  }) async {
    if (!_blobIdPattern.hasMatch(blobId) || plaintext.isEmpty) {
      return const FailureResult(ValidationFailure());
    }
    final session = _requireSession();
    if (session is FailureResult<_BlobSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_BlobSession>).data;
    final written = await _encryptPlaintextToFile(
      file: await _fileFor(authenticated.userId, blobId),
      plaintext: plaintext,
      vaultKey: authenticated.vaultKey,
    );
    if (written is FailureResult<void>) {
      return written;
    }
    _cache[blobId] = Uint8List.fromList(plaintext);
    return const Success(null);
  }

  Future<Result<void>> _encryptPlaintextToFile({
    required File file,
    required Uint8List plaintext,
    required Uint8List vaultKey,
  }) async {
    final encrypted = await _crypto.encrypt(
      plaintext: plaintext,
      key: vaultKey,
    );
    if (encrypted is FailureResult<EncryptedPayload>) {
      return FailureResult(encrypted.failure);
    }
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        _encode((encrypted as Success<EncryptedPayload>).data),
        flush: true,
      );
    } catch (_) {
      return const FailureResult(DatabaseFailure());
    }
    return const Success(null);
  }

  @override
  Future<Result<Uint8List>> read(String blobId) async {
    if (!_blobIdPattern.hasMatch(blobId)) {
      return const FailureResult(ValidationFailure());
    }
    final cached = _cache[blobId];
    if (cached != null) {
      return Success(Uint8List.fromList(cached));
    }

    final session = _requireSession();
    if (session is FailureResult<_BlobSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_BlobSession>).data;

    late final Uint8List bytes;
    try {
      final file = await _fileFor(authenticated.userId, blobId);
      if (!await file.exists()) {
        return const FailureResult(ValidationFailure());
      }
      bytes = Uint8List.fromList(await file.readAsBytes());
    } catch (_) {
      return const FailureResult(DatabaseFailure());
    }

    final payload = _decode(bytes);
    if (payload == null) {
      return const FailureResult(CryptoFailure());
    }
    final decrypted = await _crypto.decrypt(
      payload: payload,
      key: authenticated.vaultKey,
    );
    if (decrypted is FailureResult<Uint8List>) {
      return FailureResult(decrypted.failure);
    }
    final plaintext = (decrypted as Success<Uint8List>).data;
    _cache[blobId] = Uint8List.fromList(plaintext);
    return Success(plaintext);
  }

  @override
  Future<Result<void>> delete(String blobId) {
    return deleteMany([blobId]);
  }

  @override
  Future<Result<void>> deleteMany(Iterable<String> blobIds) async {
    final session = _requireSession();
    if (session is FailureResult<_BlobSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_BlobSession>).data;

    try {
      for (final blobId in blobIds) {
        if (!_blobIdPattern.hasMatch(blobId)) {
          continue;
        }
        _cache.remove(blobId);
        final file = await _fileFor(authenticated.userId, blobId);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      return const FailureResult(DatabaseFailure());
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> replaceAll(Map<String, Uint8List> blobs) async {
    final installed = await installReplace(blobs);
    if (installed is FailureResult<void>) {
      return installed;
    }
    return finalizeReplace();
  }

  @override
  Future<Result<void>> installReplace(Map<String, Uint8List> blobs) async {
    final session = _requireSession();
    if (session is FailureResult<_BlobSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_BlobSession>).data;
    for (final entry in blobs.entries) {
      if (!_blobIdPattern.hasMatch(entry.key) || entry.value.isEmpty) {
        return const FailureResult(ValidationFailure());
      }
    }

    final dirs = await _userDirs(authenticated.userId);
    try {
      await _deleteDirIfExists(dirs.next);
      await dirs.next.create(recursive: true);
      for (final entry in blobs.entries) {
        final written = await _encryptPlaintextToFile(
          file: File('${dirs.next.path}${Platform.pathSeparator}${entry.key}'),
          plaintext: entry.value,
          vaultKey: authenticated.vaultKey,
        );
        if (written is FailureResult<void>) {
          await _deleteDirIfExists(dirs.next);
          return written;
        }
      }

      if (await dirs.live.exists()) {
        await _deleteDirIfExists(dirs.prev);
        await dirs.live.rename(dirs.prev.path);
      }
      await dirs.next.rename(dirs.live.path);
    } catch (_) {
      try {
        if (await dirs.prev.exists() && !await dirs.live.exists()) {
          await dirs.prev.rename(dirs.live.path);
        }
      } catch (_) {}
      try {
        await _deleteDirIfExists(dirs.next);
      } catch (_) {}
      return const FailureResult(DatabaseFailure());
    }
    _cache.clear();
    return const Success(null);
  }

  @override
  Future<Result<void>> rollbackReplace() async {
    final session = _requireSession();
    if (session is FailureResult<_BlobSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_BlobSession>).data;
    final dirs = await _userDirs(authenticated.userId);
    try {
      if (await dirs.prev.exists()) {
        await _deleteDirIfExists(dirs.live);
        await dirs.prev.rename(dirs.live.path);
      } else {
        await _deleteDirIfExists(dirs.live);
      }
      await _deleteDirIfExists(dirs.next);
    } catch (_) {
      return const FailureResult(DatabaseFailure());
    }
    _cache.clear();
    return const Success(null);
  }

  @override
  Future<Result<void>> finalizeReplace() async {
    final session = _requireSession();
    if (session is FailureResult<_BlobSession>) {
      return FailureResult(session.failure);
    }
    final authenticated = (session as Success<_BlobSession>).data;
    try {
      final dirs = await _userDirs(authenticated.userId);
      await _deleteDirIfExists(dirs.prev);
      await _deleteDirIfExists(dirs.next);
    } catch (_) {
      return const FailureResult(DatabaseFailure());
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAllForCurrentUser() async {
    final session = _requireSession();
    if (session is FailureResult<_BlobSession>) {
      return FailureResult(session.failure);
    }
    return deleteAllForUser((session as Success<_BlobSession>).data.userId);
  }

  @override
  Future<Result<void>> deleteAllForUser(String userId) async {
    if (!_isSafeUserId(userId)) {
      return const FailureResult(ValidationFailure());
    }
    _cache.clear();
    try {
      final dirs = await _userDirs(userId);
      await _deleteDirIfExists(dirs.live);
      await _deleteDirIfExists(dirs.next);
      await _deleteDirIfExists(dirs.prev);
    } catch (_) {
      return const FailureResult(DatabaseFailure());
    }
    return const Success(null);
  }

  @override
  void clearCache() {
    _cache.clear();
  }

  Result<_BlobSession> _requireSession() {
    final current = _session.current;
    final vaultKey = _session.vaultKey;
    if (current == null ||
        vaultKey == null ||
        vaultKey.length != SecurityConstants.vaultKeyLength) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(
      _BlobSession(userId: current.userId, vaultKey: vaultKey),
    );
  }

  Future<Directory> _root() async {
    if (_supportDirectory != null) {
      return _supportDirectory();
    }
    return getApplicationSupportDirectory();
  }

  Future<Directory> _userDirectory(String userId) async {
    final root = await _root();
    return Directory('${root.path}${Platform.pathSeparator}vault_blobs'
        '${Platform.pathSeparator}$userId');
  }

  Future<_BlobDirs> _userDirs(String userId) async {
    final live = await _userDirectory(userId);
    return _BlobDirs(
      live: live,
      next: Directory('${live.path}.next'),
      prev: Directory('${live.path}.prev'),
    );
  }

  static Future<void> _deleteDirIfExists(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  static bool _isSafeUserId(String userId) {
    return userId.isNotEmpty &&
        !userId.contains('/') &&
        !userId.contains('\\') &&
        !userId.contains('..');
  }

  Future<File> _fileFor(String userId, String blobId) async {
    final directory = await _userDirectory(userId);
    return File(
      '${directory.path}${Platform.pathSeparator}$blobId',
    );
  }

  Uint8List _encode(EncryptedPayload payload) {
    final bytes = BytesBuilder(copy: false)
      ..addByte(_fileVersion)
      ..add(payload.nonce)
      ..add(payload.authenticationTag)
      ..add(payload.ciphertext);
    return bytes.toBytes();
  }

  EncryptedPayload? _decode(Uint8List bytes) {
    final header =
        1 +
        SecurityConstants.nonceLength +
        SecurityConstants.authenticationTagLength;
    if (bytes.length <= header || bytes[0] != _fileVersion) {
      return null;
    }
    var offset = 1;
    final nonce = bytes.sublist(
      offset,
      offset + SecurityConstants.nonceLength,
    );
    offset += SecurityConstants.nonceLength;
    final tag = bytes.sublist(
      offset,
      offset + SecurityConstants.authenticationTagLength,
    );
    offset += SecurityConstants.authenticationTagLength;
    return EncryptedPayload(
      version: SecurityConstants.vaultEncryptionVersion,
      nonce: Uint8List.fromList(nonce),
      ciphertext: Uint8List.fromList(bytes.sublist(offset)),
      authenticationTag: Uint8List.fromList(tag),
    );
  }

  static String _toHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final value in bytes) {
      buffer.write(value.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

class _BlobSession {
  const _BlobSession({required this.userId, required this.vaultKey});

  final String userId;
  final Uint8List vaultKey;
}

class _BlobDirs {
  const _BlobDirs({
    required this.live,
    required this.next,
    required this.prev,
  });

  final Directory live;
  final Directory next;
  final Directory prev;
}
