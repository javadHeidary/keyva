import 'package:keyva/feature/category/model/category_defaults.dart';
import 'package:keyva/feature/vault/model/bank_card_item.dart';
import 'package:keyva/feature/vault/model/category_item.dart';
import 'package:keyva/feature/vault/model/login_item.dart';
import 'package:keyva/feature/vault/model/secure_note_item.dart';

class VaultData {
  VaultData({
    required this.version,
    required List<LoginItem> logins,
    required List<BankCardItem> bankCards,
    required List<SecureNoteItem> secureNotes,
    required List<CategoryItem> categories,
  }) : logins = List<LoginItem>.unmodifiable(logins),
       bankCards = List<BankCardItem>.unmodifiable(bankCards),
       secureNotes = List<SecureNoteItem>.unmodifiable(secureNotes),
       categories = List<CategoryItem>.unmodifiable(categories);

  static const int currentVersion = 1;
  static const int maxPinnedItems = 5;

  factory VaultData.initial() {
    return VaultData(
      version: currentVersion,
      logins: const [],
      bankCards: const [],
      secureNotes: const [],
      categories: CategoryDefaults.items,
    );
  }

  final int version;
  final List<LoginItem> logins;
  final List<BankCardItem> bankCards;
  final List<SecureNoteItem> secureNotes;
  final List<CategoryItem> categories;

  int get pinnedItemCount {
    var count = 0;
    for (final item in logins) {
      if (item.isPinned) count++;
    }
    for (final item in bankCards) {
      if (item.isPinned) count++;
    }
    for (final item in secureNotes) {
      if (item.isPinned) count++;
    }
    return count;
  }

  @override
  bool operator ==(Object other) {
    return other is VaultData &&
        version == other.version &&
        _listEquals(logins, other.logins) &&
        _listEquals(bankCards, other.bankCards) &&
        _listEquals(secureNotes, other.secureNotes) &&
        _listEquals(categories, other.categories);
  }

  @override
  int get hashCode => Object.hash(
    version,
    Object.hashAll(logins),
    Object.hashAll(bankCards),
    Object.hashAll(secureNotes),
    Object.hashAll(categories),
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
