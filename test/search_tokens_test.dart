import 'package:nlevel_booking_core/nlevel_booking_core.dart';
import 'package:test/test.dart';

void main() {
  test('prefixTokens начинается с minLen и обрезается по maxLen', () {
    expect(SearchTokens.prefixTokens('Иван'), ['ив', 'ива', 'иван']);
    expect(SearchTokens.prefixTokens('abcdef', maxLen: 3), ['ab', 'abc']);
    expect(SearchTokens.prefixTokens('   '), isEmpty);
  });

  test('textTokens: слова, их префиксы и полная строка', () {
    final tokens = SearchTokens.textTokens('Иван Петров');
    expect(tokens, containsAll(['иван', 'ив', 'петров', 'пет', 'иван петров']));
    expect(tokens.toSet(), hasLength(tokens.length), reason: 'без дублей');
  });

  test('phonePrefixTokens начинается с 4 цифр', () {
    expect(SearchTokens.phonePrefixTokens('79991'), ['7999', '79991']);
    expect(SearchTokens.phonePrefixTokens('799'), isEmpty);
  });
}
