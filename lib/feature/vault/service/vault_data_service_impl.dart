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
import 'package:keyva/feature/vault/repository/vault_repository.dart';
import 'package:keyva/feature/vault/serialization/vault_serializer.dart';
import 'package:keyva/feature/vault/service/vault_data_service.dart';
import 'package:keyva/feature/vault/session/vault_session.dart';

class VaultDataServiceImpl implements VaultDataService {
  VaultDataServiceImpl({
    required VaultSerializer serializer,
    required VaultRepository vaults,
    required VaultSession vaultSession,
  }) : _serializer = serializer,
       _vaults = vaults,
       _vaultSession = vaultSession;

  final VaultSerializer _serializer;
  final VaultRepository _vaults;
  final VaultSession _vaultSession;

  Future<void> _tail = Future<void>.value();

  @override
  Future<Result<void>> addLogin(LoginItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _addItem(current.logins, item, (login) => login.id),
          (logins) => _rebuild(current, logins: logins),
        );
      }),
    );
  }

  @override
  Future<Result<void>> updateLogin(LoginItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _replaceItem(current.logins, item, (login) => login.id),
          (logins) => _rebuild(current, logins: logins),
        );
      }),
    );
  }

  @override
  Future<Result<void>> deleteLogin(String id) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _removeItem(current.logins, id, (login) => login.id),
          (logins) => _rebuild(current, logins: logins),
        );
      }),
    );
  }

  @override
  Future<Result<void>> addBankCard(BankCardItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _addItem(current.bankCards, item, (card) => card.id),
          (bankCards) => _rebuild(current, bankCards: bankCards),
        );
      }),
    );
  }

  @override
  Future<Result<void>> updateBankCard(BankCardItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _replaceItem(current.bankCards, item, (card) => card.id),
          (bankCards) => _rebuild(current, bankCards: bankCards),
        );
      }),
    );
  }

  @override
  Future<Result<void>> deleteBankCard(String id) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _removeItem(current.bankCards, id, (card) => card.id),
          (bankCards) => _rebuild(current, bankCards: bankCards),
        );
      }),
    );
  }

  @override
  Future<Result<void>> addSecureNote(SecureNoteItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _addItem(current.secureNotes, item, (note) => note.id),
          (secureNotes) => _rebuild(current, secureNotes: secureNotes),
        );
      }),
    );
  }

  @override
  Future<Result<void>> updateSecureNote(SecureNoteItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _replaceItem(current.secureNotes, item, (note) => note.id),
          (secureNotes) => _rebuild(current, secureNotes: secureNotes),
        );
      }),
    );
  }

  @override
  Future<Result<void>> deleteSecureNote(String id) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _removeItem(current.secureNotes, id, (note) => note.id),
          (secureNotes) => _rebuild(current, secureNotes: secureNotes),
        );
      }),
    );
  }

  @override
  Future<Result<void>> addCategory(CategoryItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _addItem(current.categories, item, (category) => category.id),
          (categories) => _rebuild(current, categories: categories),
        );
      }),
    );
  }

  @override
  Future<Result<void>> updateCategory(CategoryItem item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _replaceItem(current.categories, item, (category) => category.id),
          (categories) => _rebuild(current, categories: categories),
        );
      }),
    );
  }

  @override
  Future<Result<void>> deleteCategory(String id) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _removeItem(current.categories, id, (category) => category.id),
          (categories) => _rebuild(current, categories: categories),
        );
      }),
    );
  }

  @override
  Future<Result<void>> addImageFolder(ImageFolder item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _addItem(current.imageFolders, item, (folder) => folder.id),
          (imageFolders) => _rebuild(current, imageFolders: imageFolders),
        );
      }),
    );
  }

  @override
  Future<Result<void>> updateImageFolder(ImageFolder item) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _replaceItem(current.imageFolders, item, (folder) => folder.id),
          (imageFolders) => _rebuild(current, imageFolders: imageFolders),
        );
      }),
    );
  }

  @override
  Future<Result<void>> deleteImageFolder(String id) {
    return _enqueue(
      () => _mutate((current) {
        final folders = _removeItem(
          current.imageFolders,
          id,
          (folder) => folder.id,
        );
        if (folders is FailureResult<List<ImageFolder>>) {
          return FailureResult(folders.failure);
        }
        final remainingImages = [
          for (final image in current.images)
            if (image.folderId != id) image,
        ];
        return Success(
          _rebuild(
            current,
            imageFolders: (folders as Success<List<ImageFolder>>).data,
            images: remainingImages,
          ),
        );
      }),
    );
  }

  @override
  Future<Result<void>> addImage(ImageItem item) {
    return _enqueue(
      () => _mutate((current) {
        if (!current.imageFolders.any((folder) => folder.id == item.folderId)) {
          return const FailureResult(ValidationFailure());
        }
        return _withCollection(
          _addItem(current.images, item, (image) => image.id),
          (images) => _rebuild(current, images: images),
        );
      }),
    );
  }

  @override
  Future<Result<void>> updateImage(ImageItem item) {
    return _enqueue(
      () => _mutate((current) {
        if (!current.imageFolders.any((folder) => folder.id == item.folderId)) {
          return const FailureResult(ValidationFailure());
        }
        return _withCollection(
          _replaceItem(current.images, item, (image) => image.id),
          (images) => _rebuild(current, images: images),
        );
      }),
    );
  }

  @override
  Future<Result<void>> deleteImage(String id) {
    return _enqueue(
      () => _mutate((current) {
        return _withCollection(
          _removeItem(current.images, id, (image) => image.id),
          (images) => _rebuild(current, images: images),
        );
      }),
    );
  }

  @override
  Future<Result<void>> replaceVault(VaultData restoredVault) {
    return _enqueue(() => _replaceVault(restoredVault));
  }

  Future<Result<void>> _replaceVault(VaultData restoredVault) async {
    if (!_vaultSession.isUnlocked) {
      return const FailureResult(AuthenticationFailure());
    }
    if (_vaultSession.vaultData == null) {
      return const FailureResult(AuthenticationFailure());
    }

    final serialized = await _serializer.serialize(restoredVault);
    if (serialized is FailureResult<Uint8List>) {
      return FailureResult(serialized.failure);
    }

    final saved = await _vaults.saveVaultData(
      (serialized as Success<Uint8List>).data,
    );
    if (saved is FailureResult<void>) {
      return FailureResult(saved.failure);
    }

    if (!_vaultSession.isUnlocked) {
      return const FailureResult(AuthenticationFailure());
    }

    return _vaultSession.unlock(restoredVault);
  }

  Future<Result<void>> _enqueue(Future<Result<void>> Function() action) {
    final previous = _tail;
    final operation = previous.then((_) => action());
    _tail = operation.then((_) {}, onError: (_) {});
    return operation;
  }

  Future<Result<void>> _mutate(
    Result<VaultData> Function(VaultData current) buildCandidate,
  ) async {
    if (!_vaultSession.isUnlocked) {
      return const FailureResult(AuthenticationFailure());
    }
    final current = _vaultSession.vaultData;
    if (current == null) {
      return const FailureResult(AuthenticationFailure());
    }

    final candidateResult = buildCandidate(current);
    if (candidateResult is FailureResult<VaultData>) {
      return FailureResult(candidateResult.failure);
    }
    final candidate = (candidateResult as Success<VaultData>).data;

    final serialized = await _serializer.serialize(candidate);
    if (serialized is FailureResult<Uint8List>) {
      return FailureResult(serialized.failure);
    }

    final saved = await _vaults.saveVaultData(
      (serialized as Success<Uint8List>).data,
    );
    if (saved is FailureResult<void>) {
      return FailureResult(saved.failure);
    }

    return _vaultSession.unlock(candidate);
  }

  Result<VaultData> _withCollection<T>(
    Result<List<T>> collection,
    VaultData Function(List<T> items) rebuild,
  ) {
    if (collection is FailureResult<List<T>>) {
      return FailureResult(collection.failure);
    }
    return Success(rebuild((collection as Success<List<T>>).data));
  }

  Result<List<T>> _addItem<T>(
    List<T> items,
    T item,
    String Function(T item) idOf,
  ) {
    final id = idOf(item);
    if (items.any((existing) => idOf(existing) == id)) {
      return const FailureResult(ValidationFailure());
    }
    return Success([...items, item]);
  }

  Result<List<T>> _replaceItem<T>(
    List<T> items,
    T item,
    String Function(T item) idOf,
  ) {
    final id = idOf(item);
    final index = items.indexWhere((existing) => idOf(existing) == id);
    if (index < 0) {
      return const FailureResult(ValidationFailure());
    }
    final copy = List<T>.of(items);
    copy[index] = item;
    return Success(copy);
  }

  Result<List<T>> _removeItem<T>(
    List<T> items,
    String id,
    String Function(T item) idOf,
  ) {
    final index = items.indexWhere((existing) => idOf(existing) == id);
    if (index < 0) {
      return const FailureResult(ValidationFailure());
    }
    final copy = List<T>.of(items)..removeAt(index);
    return Success(copy);
  }

  VaultData _rebuild(
    VaultData current, {
    List<LoginItem>? logins,
    List<BankCardItem>? bankCards,
    List<SecureNoteItem>? secureNotes,
    List<CategoryItem>? categories,
    List<ImageFolder>? imageFolders,
    List<ImageItem>? images,
  }) {
    return VaultData(
      version: current.version,
      logins: logins ?? current.logins,
      bankCards: bankCards ?? current.bankCards,
      secureNotes: secureNotes ?? current.secureNotes,
      categories: categories ?? current.categories,
      imageFolders: imageFolders ?? current.imageFolders,
      images: images ?? current.images,
    );
  }
}
