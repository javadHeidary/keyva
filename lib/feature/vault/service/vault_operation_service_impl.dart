import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/blob/encrypted_blob_store.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/service/vault_operation_service.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';

class VaultOperationServiceImpl implements VaultOperationService {
  VaultOperationServiceImpl({
    required VaultDataService vaultData,
    required VaultSession vaultSession,
    EncryptedBlobStore? blobs,
  }) : _vaultData = vaultData,
       _vaultSession = vaultSession,
       _blobs = blobs;

  final VaultDataService _vaultData;
  final VaultSession _vaultSession;
  final EncryptedBlobStore? _blobs;

  @override
  Future<Result<VaultData>> getVault() async {
    if (!_vaultSession.isUnlocked) {
      return const FailureResult(AuthenticationFailure());
    }
    final current = _vaultSession.vaultData;
    if (current == null) {
      return const FailureResult(AuthenticationFailure());
    }
    return Success(current);
  }

  @override
  Future<Result<Object>> getItemById(String id) async {
    final vaultResult = await getVault();
    if (vaultResult is FailureResult<VaultData>) {
      return FailureResult(vaultResult.failure);
    }
    final item = _findItem((vaultResult as Success<VaultData>).data, id);
    if (item == null) {
      return const FailureResult(ValidationFailure());
    }
    return Success(item);
  }

  @override
  Future<Result<void>> addItem(Object item) {
    return switch (item) {
      LoginItem login => _vaultData.addLogin(login),
      BankCardItem card => _vaultData.addBankCard(card),
      SecureNoteItem note => _vaultData.addSecureNote(note),
      CategoryItem category => _vaultData.addCategory(category),
      ImageFolder folder => _vaultData.addImageFolder(folder),
      ImageItem image => _vaultData.addImage(image),
      _ => Future.value(const FailureResult(ValidationFailure())),
    };
  }

  @override
  Future<Result<void>> updateItem(Object item) {
    return switch (item) {
      LoginItem login => _vaultData.updateLogin(login),
      BankCardItem card => _vaultData.updateBankCard(card),
      SecureNoteItem note => _vaultData.updateSecureNote(note),
      CategoryItem category => _vaultData.updateCategory(category),
      ImageFolder folder => _vaultData.updateImageFolder(folder),
      ImageItem image => _vaultData.updateImage(image),
      _ => Future.value(const FailureResult(ValidationFailure())),
    };
  }

  @override
  Future<Result<void>> deleteItem(String id) async {
    final vaultResult = await getVault();
    if (vaultResult is FailureResult<VaultData>) {
      return FailureResult(vaultResult.failure);
    }
    final vault = (vaultResult as Success<VaultData>).data;
    if (vault.logins.any((login) => login.id == id)) {
      return _vaultData.deleteLogin(id);
    }
    if (vault.bankCards.any((card) => card.id == id)) {
      return _vaultData.deleteBankCard(id);
    }
    if (vault.secureNotes.any((note) => note.id == id)) {
      return _vaultData.deleteSecureNote(id);
    }
    if (vault.categories.any((category) => category.id == id)) {
      return _vaultData.deleteCategory(id);
    }

    final folder = _folderById(vault, id);
    if (folder != null) {
      final blobIds = [
        for (final image in vault.images)
          if (image.folderId == id) ...[image.blobId, image.thumbnailBlobId],
      ];
      final deleted = await _vaultData.deleteImageFolder(id);
      if (deleted is FailureResult<void>) {
        return deleted;
      }
      await _blobs?.deleteMany(blobIds);
      return deleted;
    }

    final image = _imageById(vault, id);
    if (image != null) {
      final deleted = await _vaultData.deleteImage(id);
      if (deleted is FailureResult<void>) {
        return deleted;
      }
      await _blobs?.deleteMany([image.blobId, image.thumbnailBlobId]);
      return deleted;
    }
    return const FailureResult(ValidationFailure());
  }

  @override
  Future<Result<void>> setItemPinned({
    required String id,
    required bool isPinned,
  }) async {
    final vaultResult = await getVault();
    if (vaultResult is FailureResult<VaultData>) {
      return FailureResult(vaultResult.failure);
    }
    final vault = (vaultResult as Success<VaultData>).data;
    final item = _findVaultEntry(vault, id);
    if (item == null) {
      return const FailureResult(ValidationFailure());
    }

    final currentlyPinned = _isPinned(item);
    if (currentlyPinned == isPinned) {
      return const Success(null);
    }
    if (isPinned && vault.pinnedItemCount >= VaultData.maxPinnedItems) {
      return const FailureResult(PinLimitFailure());
    }

    return switch (item) {
      LoginItem login => _vaultData.updateLogin(
        login.copyWith(isPinned: isPinned),
      ),
      BankCardItem card => _vaultData.updateBankCard(
        card.copyWith(isPinned: isPinned),
      ),
      SecureNoteItem note => _vaultData.updateSecureNote(
        note.copyWith(isPinned: isPinned),
      ),
      ImageFolder folder => _vaultData.updateImageFolder(
        folder.copyWith(isPinned: isPinned),
      ),
      _ => const FailureResult(ValidationFailure()),
    };
  }

  static ImageFolder? _folderById(VaultData vault, String id) {
    for (final folder in vault.imageFolders) {
      if (folder.id == id) {
        return folder;
      }
    }
    return null;
  }

  static ImageItem? _imageById(VaultData vault, String id) {
    for (final image in vault.images) {
      if (image.id == id) {
        return image;
      }
    }
    return null;
  }

  static Object? _findVaultEntry(VaultData vault, String id) {
    for (final login in vault.logins) {
      if (login.id == id) {
        return login;
      }
    }
    for (final card in vault.bankCards) {
      if (card.id == id) {
        return card;
      }
    }
    for (final note in vault.secureNotes) {
      if (note.id == id) {
        return note;
      }
    }
    for (final folder in vault.imageFolders) {
      if (folder.id == id) {
        return folder;
      }
    }
    return null;
  }

  static bool _isPinned(Object item) {
    return switch (item) {
      LoginItem login => login.isPinned,
      BankCardItem card => card.isPinned,
      SecureNoteItem note => note.isPinned,
      ImageFolder folder => folder.isPinned,
      _ => false,
    };
  }

  static Object? _findItem(VaultData vault, String id) {
    for (final login in vault.logins) {
      if (login.id == id) {
        return login;
      }
    }
    for (final card in vault.bankCards) {
      if (card.id == id) {
        return card;
      }
    }
    for (final note in vault.secureNotes) {
      if (note.id == id) {
        return note;
      }
    }
    for (final folder in vault.imageFolders) {
      if (folder.id == id) {
        return folder;
      }
    }
    for (final image in vault.images) {
      if (image.id == id) {
        return image;
      }
    }
    for (final category in vault.categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}
