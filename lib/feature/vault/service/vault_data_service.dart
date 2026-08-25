import 'package:keyva/core/exceptions/result.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/image_folder.dart';
import 'package:keyva/feature/vault/model/image_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';
import 'package:keyva/feature/vault/model/vault_data.dart';

abstract interface class VaultDataService {
  Future<Result<void>> addLogin(LoginItem item);

  Future<Result<void>> updateLogin(LoginItem item);

  Future<Result<void>> deleteLogin(String id);

  Future<Result<void>> addBankCard(BankCardItem item);

  Future<Result<void>> updateBankCard(BankCardItem item);

  Future<Result<void>> deleteBankCard(String id);

  Future<Result<void>> addSecureNote(SecureNoteItem item);

  Future<Result<void>> updateSecureNote(SecureNoteItem item);

  Future<Result<void>> deleteSecureNote(String id);

  Future<Result<void>> addCategory(CategoryItem item);

  Future<Result<void>> updateCategory(CategoryItem item);

  Future<Result<void>> deleteCategory(String id);

  Future<Result<void>> addImageFolder(ImageFolder item);

  Future<Result<void>> updateImageFolder(ImageFolder item);

  Future<Result<void>> deleteImageFolder(String id);

  Future<Result<void>> addImage(ImageItem item);

  Future<Result<void>> updateImage(ImageItem item);

  Future<Result<void>> deleteImage(String id);

  Future<Result<void>> replaceVault(VaultData restoredVault);
}
