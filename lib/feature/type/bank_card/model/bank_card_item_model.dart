class BankCardItem {
  const BankCardItem({
    required this.id,
    required this.title,
    required this.cardNumber,
    required this.bankTitle,
    required this.expiry,
    required this.cvv,
    required this.createdAt,
    this.categoryId,
    this.notes,
  });

  final String id;
  final String? categoryId;
  final String title;
  final String cardNumber;
  final String bankTitle;
  final String expiry;
  final String cvv;
  final String? notes;
  final DateTime createdAt;

  BankCardItem copyWith({
    String? id,
    String? categoryId,
    bool clearCategoryId = false,
    String? title,
    String? cardNumber,
    String? bankTitle,
    String? expiry,
    String? cvv,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
  }) {
    return BankCardItem(
      id: id ?? this.id,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      title: title ?? this.title,
      cardNumber: cardNumber ?? this.cardNumber,
      bankTitle: bankTitle ?? this.bankTitle,
      expiry: expiry ?? this.expiry,
      cvv: cvv ?? this.cvv,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
