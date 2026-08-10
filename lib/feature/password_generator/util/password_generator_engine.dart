import 'dart:math';

import 'package:keyva/feature/password_generator/model/password_generator_settings.dart';

class PasswordGeneratorException implements Exception {
  PasswordGeneratorException(this.message);
  final String message;
}

const _similarCharacters = {'I', 'i', 'l', '1', 'L', 'o', 'O', '0'};

const _uppercasePool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _lowercasePool = 'abcdefghijklmnopqrstuvwxyz';
const _numbersPool = '0123456789';
const _symbolsPool = '@#\$%!';

String _filterPool(String pool, bool excludeSimilar) {
  if (!excludeSimilar) return pool;
  return pool.split('').where((c) => !_similarCharacters.contains(c)).join();
}

String generateSecurePassword(PasswordGeneratorSettings settings) {
  final pools = <String>[];
  if (settings.uppercase) {
    pools.add(_filterPool(_uppercasePool, settings.excludeSimilar));
  }
  if (settings.lowercase) {
    pools.add(_filterPool(_lowercasePool, settings.excludeSimilar));
  }
  if (settings.numbers) {
    pools.add(_filterPool(_numbersPool, settings.excludeSimilar));
  }
  if (settings.symbols) {
    pools.add(_filterPool(_symbolsPool, settings.excludeSimilar));
  }

  final nonEmptyPools = pools.where((p) => p.isNotEmpty).toList();
  if (nonEmptyPools.isEmpty) {
    throw PasswordGeneratorException('حداقل یک نوع کاراکتر باید فعال باشد');
  }

  final length = settings.length.clamp(
    PasswordGeneratorSettings.minLength,
    PasswordGeneratorSettings.maxLength,
  );

  if (length < nonEmptyPools.length) {
    throw PasswordGeneratorException(
      'طول رمز برای گروه‌های فعال کافی نیست',
    );
  }

  final random = Random.secure();
  final chars = <String>[];

  for (final pool in nonEmptyPools) {
    chars.add(pool[_secureIndex(random, pool.length)]);
  }

  final allChars = nonEmptyPools.join();
  while (chars.length < length) {
    chars.add(allChars[_secureIndex(random, allChars.length)]);
  }

  _secureShuffle(chars, random);
  return chars.join();
}

int _secureIndex(Random random, int length) {
  return random.nextInt(length);
}

void _secureShuffle(List<String> chars, Random random) {
  for (var i = chars.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final temp = chars[i];
    chars[i] = chars[j];
    chars[j] = temp;
  }
}
