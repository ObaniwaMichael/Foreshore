/// All amounts are whole Nigerian Naira (nearest naira).
class Money {
  const Money(this.naira);

  final int naira;

  static Money fromJson(dynamic value) {
    if (value is int) return Money(value);
    if (value is num) return Money(value.round());
    if (value is String) return Money(int.parse(value));
    throw ArgumentError('Invalid money value: $value');
  }

  int toJson() => naira;

  String get formatted {
    final s = naira.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    final sign = naira < 0 ? '-' : '';
    return '$sign₦$buf';
  }

  Money operator +(Money other) => Money(naira + other.naira);
  Money operator -(Money other) => Money(naira - other.naira);

  @override
  String toString() => formatted;

  @override
  bool operator ==(Object other) => other is Money && other.naira == naira;

  @override
  int get hashCode => naira.hashCode;
}
