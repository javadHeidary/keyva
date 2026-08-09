import 'package:flutter_test/flutter_test.dart';
import 'package:iranian_banks/iranian_banks.dart';
import 'package:keyva/feature/type/bank_card/util/bank_card_util.dart';

const kSeedBankCardPan = '6104330000000003';

void main() {
  test('seed bank card PAN is valid', () {
    expect(isValidBankCardDigits(kSeedBankCardPan), isTrue);
    expect(IranianBanks.verifyCardNumber(kSeedBankCardPan), isTrue);
    expect(IranianBanks.getBankFromCard(kSeedBankCardPan)?.title, isNotEmpty);
  });
}
