class BankCardItem {
  const BankCardItem({
    required this.id,
    required this.title,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    required this.bankName,
    required this.notes,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final String bankName;
  final String? notes;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is BankCardItem &&
        id == other.id &&
        title == other.title &&
        cardNumber == other.cardNumber &&
        cardHolder == other.cardHolder &&
        expiryDate == other.expiryDate &&
        cvv == other.cvv &&
        bankName == other.bankName &&
        notes == other.notes &&
        categoryId == other.categoryId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    cardNumber,
    cardHolder,
    expiryDate,
    cvv,
    bankName,
    notes,
    categoryId,
    createdAt,
    updatedAt,
  );
}
