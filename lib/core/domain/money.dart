class Money implements Comparable<Money> {
  const Money.centavos(this.centavos);

  factory Money.php(int pesos, [int centavos = 0]) {
    if (centavos < 0 || centavos > 99) {
      throw ArgumentError.value(
        centavos,
        'centavos',
        'Must be between 0 and 99.',
      );
    }
    return Money.centavos((pesos * 100) + centavos);
  }

  static const zero = Money.centavos(0);

  final int centavos;

  bool get isZero => centavos == 0;
  bool get isPositive => centavos > 0;
  bool get isNegative => centavos < 0;

  Money operator +(Money other) => Money.centavos(centavos + other.centavos);

  Money operator -(Money other) => Money.centavos(centavos - other.centavos);

  bool operator <(Money other) => centavos < other.centavos;

  bool operator <=(Money other) => centavos <= other.centavos;

  bool operator >(Money other) => centavos > other.centavos;

  bool operator >=(Money other) => centavos >= other.centavos;

  @override
  int compareTo(Money other) => centavos.compareTo(other.centavos);

  String formatPhp() {
    final sign = centavos < 0 ? '-' : '';
    final absolute = centavos.abs();
    final pesos = absolute ~/ 100;
    final remainder = absolute % 100;
    return '${sign}PHP $pesos.${remainder.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => formatPhp();

  @override
  bool operator ==(Object other) {
    return other is Money && other.centavos == centavos;
  }

  @override
  int get hashCode => centavos.hashCode;
}
