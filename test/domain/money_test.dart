import 'package:audivance/core/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('uses integer centavos for arithmetic', () {
      const first = Money.centavos(12550);
      const second = Money.centavos(4750);

      expect(first + second, const Money.centavos(17300));
      expect(first - second, const Money.centavos(7800));
    });

    test('compares amounts by centavos', () {
      const smaller = Money.centavos(9999);
      const larger = Money.centavos(10000);

      expect(smaller < larger, isTrue);
      expect(larger > smaller, isTrue);
      expect(larger >= Money.php(100), isTrue);
      expect(smaller.compareTo(larger), lessThan(0));
    });

    test('rejects malformed PHP centavo input', () {
      expect(() => Money.php(10, 120), throwsArgumentError);
      expect(() => Money.php(10, -1), throwsArgumentError);
    });
  });
}
