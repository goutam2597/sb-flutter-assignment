import 'package:flutter_test/flutter_test.dart';
import 'package:starter/domain/models.dart';

void main() {
  test('four-decimal multiplication is exact', () {
    expect(Money.parse('0.0079', 'EUR').times(3), Money.parse('0.0237', 'EUR'));
  });
  test('rejects imprecise contract money', () {
    expect(() => Money.parse('0.1', 'EUR'), throwsFormatException);
  });
  test('different currencies cannot be added', () {
    expect(
      () => Money.parse('1.0000', 'EUR') + Money.parse('1.0000', 'USD'),
      throwsArgumentError,
    );
  });
}
