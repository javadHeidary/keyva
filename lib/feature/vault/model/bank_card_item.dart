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
    this.isPinned = false,
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
  final bool isPinned;

  BankCardItem copyWith({
    String? id,
    String? title,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cvv,
    String? bankName,
    String? notes,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return BankCardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      bankName: bankName ?? this.bankName,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

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
        updatedAt == other.updatedAt &&
        isPinned == other.isPinned;
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
    isPinned,
  );
}
