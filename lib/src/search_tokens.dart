/// Префиксные токены для поиска по Firestore (там нет подстрочного поиска).
class SearchTokens {
  const SearchTokens._();

  /// Creates prefix tokens for search: "иван" -> ["ив","ива","иван"]
  static List<String> prefixTokens(
    String value, {
    int minLen = 2,
    int maxLen = 24,
  }) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return [];

    final tokens = <String>[];
    final limit = v.length < maxLen ? v.length : maxLen;

    for (int i = 1; i <= limit; i++) {
      final part = v.substring(0, i);
      if (part.length >= minLen) tokens.add(part);
    }
    return tokens;
  }

  /// Splits by spaces and makes tokens for each word + full string.
  static List<String> textTokens(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return [];

    final parts = v.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final out = <String>{};

    for (final p in parts) {
      out.add(p);
      out.addAll(prefixTokens(p));
    }

    if (parts.length >= 2) {
      out.add(v);
      out.addAll(prefixTokens(v, minLen: 3));
    }

    return out.toList();
  }

  /// Phone prefix tokens for digits: 7XXXXXXXXXX -> ["7999","79991",...]
  static List<String> phonePrefixTokens(String digits11) {
    final out = <String>[];
    for (int i = 4; i <= digits11.length; i++) {
      out.add(digits11.substring(0, i));
    }
    return out;
  }
}
