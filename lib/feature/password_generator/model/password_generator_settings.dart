class PasswordGeneratorSettings {
  const PasswordGeneratorSettings({
    this.length = 16,
    this.uppercase = true,
    this.lowercase = true,
    this.numbers = true,
    this.symbols = true,
    this.excludeSimilar = false,
  });

  final int length;
  final bool uppercase;
  final bool lowercase;
  final bool numbers;
  final bool symbols;
  final bool excludeSimilar;

  static const int minLength = 6;
  static const int maxLength = 64;

  PasswordGeneratorSettings copyWith({
    int? length,
    bool? uppercase,
    bool? lowercase,
    bool? numbers,
    bool? symbols,
    bool? excludeSimilar,
  }) {
    return PasswordGeneratorSettings(
      length: length ?? this.length,
      uppercase: uppercase ?? this.uppercase,
      lowercase: lowercase ?? this.lowercase,
      numbers: numbers ?? this.numbers,
      symbols: symbols ?? this.symbols,
      excludeSimilar: excludeSimilar ?? this.excludeSimilar,
    );
  }

  Map<String, dynamic> toJson() => {
        'length': length,
        'uppercase': uppercase,
        'lowercase': lowercase,
        'numbers': numbers,
        'symbols': symbols,
        'excludeSimilar': excludeSimilar,
      };

  factory PasswordGeneratorSettings.fromJson(Map<String, dynamic> json) {
    return PasswordGeneratorSettings(
      length: (json['length'] as num?)?.toInt() ?? 16,
      uppercase: json['uppercase'] as bool? ?? true,
      lowercase: json['lowercase'] as bool? ?? true,
      numbers: json['numbers'] as bool? ?? true,
      symbols: json['symbols'] as bool? ?? true,
      excludeSimilar: json['excludeSimilar'] as bool? ?? false,
    );
  }
}
