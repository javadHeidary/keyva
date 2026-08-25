import 'dart:convert';
import 'dart:typed_data';

import 'package:keyva/core/exceptions/app_failure.dart';
import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';

class VaultSerializerImpl implements VaultSerializer {
  static const _requiredVaultKeys = {
    'version',
    'logins',
    'bankCards',
    'secureNotes',
    'categories',
  };

  static const _optionalVaultKeys = {'imageFolders', 'images'};

  static const _loginKeys = {
    'id',
    'title',
    'username',
    'password',
    'website',
    'notes',
    'categoryId',
    'createdAt',
    'updatedAt',
  };

  static const _bankCardKeys = {
    'id',
    'title',
    'cardNumber',
    'cardHolder',
    'expiryDate',
    'cvv',
    'bankName',
    'notes',
    'categoryId',
    'createdAt',
    'updatedAt',
  };

  static const _secureNoteKeys = {
    'id',
    'title',
    'content',
    'categoryId',
    'createdAt',
    'updatedAt',
  };

  static const _categoryKeys = {'id', 'name', 'icon', 'createdAt'};

  static const _imageFolderKeys = {
    'id',
    'title',
    'categoryId',
    'createdAt',
    'updatedAt',
  };

  static const _imageItemKeys = {
    'id',
    'folderId',
    'note',
    'blobId',
    'thumbnailBlobId',
    'mimeType',
    'width',
    'height',
    'createdAt',
  };

  @override
  Future<Result<Uint8List>> serialize(VaultData vault) async {
    try {
      _validateVault(vault);
      final encoded = utf8.encode(jsonEncode(_vaultToMap(vault)));
      return Success(Uint8List.fromList(encoded));
    } catch (_) {
      return const FailureResult(ValidationFailure());
    }
  }

  @override
  Future<Result<VaultData>> deserialize(Uint8List bytes) async {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      final object = _requireObject(decoded);
      _requireVaultKeys(object);
      final vault = VaultData(
        version: _requireInt(object['version']),
        logins: _requireObjectList(object['logins'], _loginFromMap),
        bankCards: _requireObjectList(object['bankCards'], _bankCardFromMap),
        secureNotes: _requireObjectList(
          object['secureNotes'],
          _secureNoteFromMap,
        ),
        categories: _requireObjectList(object['categories'], _categoryFromMap),
        imageFolders: object.containsKey('imageFolders')
            ? _requireObjectList(object['imageFolders'], _imageFolderFromMap)
            : const [],
        images: object.containsKey('images')
            ? _requireObjectList(object['images'], _imageItemFromMap)
            : const [],
      );
      _validateVault(vault);
      return Success(vault);
    } catch (_) {
      return const FailureResult(ValidationFailure());
    }
  }

  Map<String, Object?> _vaultToMap(VaultData vault) {
    return <String, Object?>{
      'version': vault.version,
      'logins': [for (final item in vault.logins) _loginToMap(item)],
      'bankCards': [for (final item in vault.bankCards) _bankCardToMap(item)],
      'secureNotes': [
        for (final item in vault.secureNotes) _secureNoteToMap(item),
      ],
      'categories': [
        for (final item in vault.categories) _categoryToMap(item),
      ],
      'imageFolders': [
        for (final item in vault.imageFolders) _imageFolderToMap(item),
      ],
      'images': [for (final item in vault.images) _imageItemToMap(item)],
    };
  }

  Map<String, Object?> _loginToMap(LoginItem item) {
    return <String, Object?>{
      'id': item.id,
      'title': item.title,
      'username': item.username,
      'password': item.password,
      'website': item.website,
      'notes': item.notes,
      'categoryId': item.categoryId,
      'isPinned': item.isPinned,
      'createdAt': _formatTimestamp(item.createdAt),
      'updatedAt': _formatTimestamp(item.updatedAt),
    };
  }

  Map<String, Object?> _bankCardToMap(BankCardItem item) {
    return <String, Object?>{
      'id': item.id,
      'title': item.title,
      'cardNumber': item.cardNumber,
      'cardHolder': item.cardHolder,
      'expiryDate': item.expiryDate,
      'cvv': item.cvv,
      'bankName': item.bankName,
      'notes': item.notes,
      'categoryId': item.categoryId,
      'isPinned': item.isPinned,
      'createdAt': _formatTimestamp(item.createdAt),
      'updatedAt': _formatTimestamp(item.updatedAt),
    };
  }

  Map<String, Object?> _secureNoteToMap(SecureNoteItem item) {
    return <String, Object?>{
      'id': item.id,
      'title': item.title,
      'content': item.content,
      'categoryId': item.categoryId,
      'isPinned': item.isPinned,
      'createdAt': _formatTimestamp(item.createdAt),
      'updatedAt': _formatTimestamp(item.updatedAt),
    };
  }

  Map<String, Object?> _categoryToMap(CategoryItem item) {
    return <String, Object?>{
      'id': item.id,
      'name': item.name,
      'icon': item.icon,
      'createdAt': _formatTimestamp(item.createdAt),
    };
  }

  Map<String, Object?> _imageFolderToMap(ImageFolder item) {
    return <String, Object?>{
      'id': item.id,
      'title': item.title,
      'categoryId': item.categoryId,
      'isPinned': item.isPinned,
      'createdAt': _formatTimestamp(item.createdAt),
      'updatedAt': _formatTimestamp(item.updatedAt),
    };
  }

  Map<String, Object?> _imageItemToMap(ImageItem item) {
    return <String, Object?>{
      'id': item.id,
      'folderId': item.folderId,
      'note': item.note,
      'blobId': item.blobId,
      'thumbnailBlobId': item.thumbnailBlobId,
      'mimeType': item.mimeType,
      'width': item.width,
      'height': item.height,
      'createdAt': _formatTimestamp(item.createdAt),
    };
  }

  LoginItem _loginFromMap(Map<String, Object?> object) {
    final isPinned = _readPinnedFlag(object, _loginKeys);
    return LoginItem(
      id: _requireString(object['id']),
      title: _requireString(object['title']),
      username: _requireString(object['username']),
      password: _requireString(object['password']),
      website: _requireNullableString(object['website']),
      notes: _requireNullableString(object['notes']),
      categoryId: _requireNullableString(object['categoryId']),
      createdAt: _requireTimestamp(object['createdAt']),
      updatedAt: _requireTimestamp(object['updatedAt']),
      isPinned: isPinned,
    );
  }

  BankCardItem _bankCardFromMap(Map<String, Object?> object) {
    final isPinned = _readPinnedFlag(object, _bankCardKeys);
    return BankCardItem(
      id: _requireString(object['id']),
      title: _requireString(object['title']),
      cardNumber: _requireString(object['cardNumber']),
      cardHolder: _requireString(object['cardHolder']),
      expiryDate: _requireString(object['expiryDate']),
      cvv: _requireString(object['cvv']),
      bankName: _requireString(object['bankName']),
      notes: _requireNullableString(object['notes']),
      categoryId: _requireNullableString(object['categoryId']),
      createdAt: _requireTimestamp(object['createdAt']),
      updatedAt: _requireTimestamp(object['updatedAt']),
      isPinned: isPinned,
    );
  }

  SecureNoteItem _secureNoteFromMap(Map<String, Object?> object) {
    final isPinned = _readPinnedFlag(object, _secureNoteKeys);
    return SecureNoteItem(
      id: _requireString(object['id']),
      title: _requireString(object['title']),
      content: _requireString(object['content']),
      categoryId: _requireNullableString(object['categoryId']),
      createdAt: _requireTimestamp(object['createdAt']),
      updatedAt: _requireTimestamp(object['updatedAt']),
      isPinned: isPinned,
    );
  }

  CategoryItem _categoryFromMap(Map<String, Object?> object) {
    _requireExactKeys(object, _categoryKeys);
    return CategoryItem(
      id: _requireString(object['id']),
      name: _requireString(object['name']),
      icon: _requireNullableString(object['icon']),
      createdAt: _requireTimestamp(object['createdAt']),
    );
  }

  ImageFolder _imageFolderFromMap(Map<String, Object?> object) {
    final isPinned = _readPinnedFlag(object, _imageFolderKeys);
    return ImageFolder(
      id: _requireString(object['id']),
      title: _requireString(object['title']),
      categoryId: _requireNullableString(object['categoryId']),
      createdAt: _requireTimestamp(object['createdAt']),
      updatedAt: _requireTimestamp(object['updatedAt']),
      isPinned: isPinned,
    );
  }

  ImageItem _imageItemFromMap(Map<String, Object?> object) {
    _requireExactKeys(object, _imageItemKeys);
    return ImageItem(
      id: _requireString(object['id']),
      folderId: _requireString(object['folderId']),
      note: _requireNullableString(object['note']),
      blobId: _requireString(object['blobId']),
      thumbnailBlobId: _requireString(object['thumbnailBlobId']),
      mimeType: _requireString(object['mimeType']),
      width: _requireInt(object['width']),
      height: _requireInt(object['height']),
      createdAt: _requireTimestamp(object['createdAt']),
    );
  }

  void _validateVault(VaultData vault) {
    if (vault.version != VaultData.currentVersion) {
      throw const _VaultSchemaException();
    }
    _requireUniqueIds(vault.logins.map((item) => item.id));
    _requireUniqueIds(vault.bankCards.map((item) => item.id));
    _requireUniqueIds(vault.secureNotes.map((item) => item.id));
    _requireUniqueIds(vault.categories.map((item) => item.id));
    _requireUniqueIds(vault.imageFolders.map((item) => item.id));
    _requireUniqueIds(vault.images.map((item) => item.id));
    _requireUniqueIds([
      ...vault.images.map((item) => item.blobId),
      ...vault.images.map((item) => item.thumbnailBlobId),
    ]);
    final folderIds = vault.imageFolders.map((item) => item.id).toSet();
    for (final image in vault.images) {
      if (!folderIds.contains(image.folderId)) {
        throw const _VaultSchemaException();
      }
      if (image.width <= 0 || image.height <= 0) {
        throw const _VaultSchemaException();
      }
      if (image.mimeType.isEmpty ||
          image.blobId.isEmpty ||
          image.thumbnailBlobId.isEmpty) {
        throw const _VaultSchemaException();
      }
    }
  }

  void _requireVaultKeys(Map<String, Object?> object) {
    for (final key in _requiredVaultKeys) {
      if (!object.containsKey(key)) {
        throw const _VaultSchemaException();
      }
    }
    for (final key in object.keys) {
      if (!_requiredVaultKeys.contains(key) &&
          !_optionalVaultKeys.contains(key)) {
        throw const _VaultSchemaException();
      }
    }
  }

  void _requireUniqueIds(Iterable<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      if (id.isEmpty || !seen.add(id)) {
        throw const _VaultSchemaException();
      }
    }
  }

  Map<String, Object?> _requireObject(Object? value) {
    if (value is! Map) {
      throw const _VaultSchemaException();
    }
    final object = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const _VaultSchemaException();
      }
      object[entry.key as String] = entry.value;
    }
    return object;
  }

  bool _readPinnedFlag(Map<String, Object?> object, Set<String> baseKeys) {
    final hasPinned = object.containsKey('isPinned');
    _requireExactKeys(
      object,
      hasPinned ? {...baseKeys, 'isPinned'} : baseKeys,
    );
    if (!hasPinned) {
      return false;
    }
    return _requireBool(object['isPinned']);
  }

  void _requireExactKeys(Map<String, Object?> object, Set<String> expected) {
    if (object.length != expected.length) {
      throw const _VaultSchemaException();
    }
    for (final key in object.keys) {
      if (!expected.contains(key)) {
        throw const _VaultSchemaException();
      }
    }
    for (final key in expected) {
      if (!object.containsKey(key)) {
        throw const _VaultSchemaException();
      }
    }
  }

  List<T> _requireObjectList<T>(
    Object? value,
    T Function(Map<String, Object?> object) parse,
  ) {
    if (value is! List) {
      throw const _VaultSchemaException();
    }
    return [for (final item in value) parse(_requireObject(item))];
  }

  int _requireInt(Object? value) {
    if (value is int) {
      return value;
    }
    throw const _VaultSchemaException();
  }

  bool _requireBool(Object? value) {
    if (value is bool) {
      return value;
    }
    throw const _VaultSchemaException();
  }

  String _requireString(Object? value) {
    if (value is String) {
      return value;
    }
    throw const _VaultSchemaException();
  }

  String? _requireNullableString(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw const _VaultSchemaException();
  }

  DateTime _requireTimestamp(Object? value) {
    if (value is! String) {
      throw const _VaultSchemaException();
    }
    final parsed = DateTime.parse(value);
    if (!parsed.isUtc) {
      return parsed.toUtc();
    }
    return parsed;
  }

  String _formatTimestamp(DateTime value) => value.toUtc().toIso8601String();
}

final class _VaultSchemaException implements Exception {
  const _VaultSchemaException();
}
