class PhoneRu {
  const PhoneRu._();

  /// Extracts digits only.
  static String digitsOnly(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digits;
  }

  /// Normalizes RU phone to digits format: 7XXXXXXXXXX
  /// Accepts: 89991234567, 79991234567, 9991234567, +7...
  /// Returns null if cannot normalize to 11 digits starting with 7.
  static String? normalizeToRuDigits11(String input) {
    var d = digitsOnly(input);

    if (d.length == 10) {
      d = '7$d';
    } else if (d.length == 11 && d.startsWith('8')) {
      d = '7${d.substring(1)}';
    }

    if (d.length == 11 && d.startsWith('7')) return d;
    return null;
  }

  /// Returns E.164 format: +7XXXXXXXXXX
  static String? toE164(String input) {
    final d = normalizeToRuDigits11(input);
    if (d == null) return null;
    return '+$d';
  }

  /// Human friendly display: +7 (999) 123-45-67
  static String? toDisplay(String input) {
    final d = normalizeToRuDigits11(input);
    if (d == null) return null;

    final a = d.substring(1, 4);
    final b = d.substring(4, 7);
    final c = d.substring(7, 9);
    final e = d.substring(9, 11);
    return '+7 ($a) $b-$c-$e';
  }

  /// Formats partially entered RU phone for text fields.
  /// Examples: 7 -> +7, 7999 -> +7 (999, 7999123 -> +7 (999) 123
  static String formatForField(String input) {
    var d = digitsOnly(input);
    if (d.isEmpty) return '';

    if (d.startsWith('8')) {
      d = '7${d.substring(1)}';
    } else if (!d.startsWith('7')) {
      d = '7$d';
    }

    if (d.length > 11) d = d.substring(0, 11);

    final buf = StringBuffer('+7');
    if (d.length <= 1) return buf.toString();

    final rest = d.substring(1);
    if (rest.isNotEmpty) {
      buf.write(' (');
      buf.write(rest.substring(0, rest.length.clamp(0, 3)));
      if (rest.length >= 3) buf.write(')');
    }
    if (rest.length > 3) {
      buf.write(' ');
      buf.write(rest.substring(3, rest.length.clamp(3, 6)));
    }
    if (rest.length > 6) {
      buf.write('-');
      buf.write(rest.substring(6, rest.length.clamp(6, 8)));
    }
    if (rest.length > 8) {
      buf.write('-');
      buf.write(rest.substring(8, rest.length.clamp(8, 10)));
    }
    return buf.toString();
  }
}
