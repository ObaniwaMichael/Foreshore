import 'package:flutter_test/flutter_test.dart';
import 'package:foreshore_core/foreshore_core.dart';

void main() {
  test('formats naira', () {
    expect(const Money(30000).formatted, '₦30,000');
  });

  test('loan repayable is principal plus 20%', () {
    expect(totalRepayable(principalNaira: 300000).naira, 360000);
  });

  test('withdrawal charge equals usual daily amount', () {
    expect(withdrawalCharge(usualDailyAmount: 1000).naira, 1000);
    expect(
      netWithdrawal(balanceNaira: 25000, usualDailyAmount: 1000).naira,
      24000,
    );
  });
}
