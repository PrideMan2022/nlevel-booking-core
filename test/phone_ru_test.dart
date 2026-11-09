import 'package:nlevel_booking_core/nlevel_booking_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeToRuDigits11', () {
    test('все привычные формы дают 7XXXXXXXXXX', () {
      const expected = '79991234567';
      for (final input in [
        '89991234567',
        '+7 (999) 123-45-67',
        '9991234567',
        '7 999 123 45 67',
      ]) {
        expect(PhoneRu.normalizeToRuDigits11(input), expected, reason: input);
      }
    });

    test('некорректные номера отклоняются', () {
      expect(PhoneRu.normalizeToRuDigits11('12345'), isNull);
      expect(PhoneRu.normalizeToRuDigits11('+1 202 555 0143'), isNull);
      expect(PhoneRu.normalizeToRuDigits11(''), isNull);
    });
  });

  test('toE164 и toDisplay', () {
    expect(PhoneRu.toE164('8 999 123-45-67'), '+79991234567');
    expect(PhoneRu.toDisplay('89991234567'), '+7 (999) 123-45-67');
    expect(PhoneRu.toDisplay('abc'), isNull);
  });

  group('formatForField', () {
    test('маска собирается по мере ввода', () {
      const steps = {
        '': '',
        '7': '+7',
        '79': '+7 (9',
        '7999': '+7 (999)',
        '7999123': '+7 (999) 123',
        '79991234': '+7 (999) 123-4',
        '7999123456': '+7 (999) 123-45-6',
        '79991234567': '+7 (999) 123-45-67',
      };
      steps.forEach((input, expected) {
        expect(PhoneRu.formatForField(input), expected, reason: input);
      });
    });

    test('8 в начале заменяется на 7, лишние цифры обрезаются', () {
      expect(PhoneRu.formatForField('89991234567'), '+7 (999) 123-45-67');
      expect(PhoneRu.formatForField('799912345678999'), '+7 (999) 123-45-67');
    });
  });
}
