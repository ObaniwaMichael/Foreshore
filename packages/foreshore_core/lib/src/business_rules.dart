import 'money.dart';

/// Withdrawal charge = one day's usual contribution (BRD default).
Money withdrawalCharge({required int usualDailyAmount}) =>
    Money(usualDailyAmount);

/// Flat 20% monthly interest on principal.
Money loanInterest({required int principalNaira, double rate = 0.20}) =>
    Money((principalNaira * rate).round());

Money totalRepayable({required int principalNaira, double rate = 0.20}) =>
    Money(principalNaira) + loanInterest(principalNaira: principalNaira, rate: rate);

Money netWithdrawal({
  required int balanceNaira,
  required int usualDailyAmount,
}) {
  final charge = withdrawalCharge(usualDailyAmount: usualDailyAmount);
  final net = balanceNaira - charge.naira;
  return Money(net < 0 ? 0 : net);
}
