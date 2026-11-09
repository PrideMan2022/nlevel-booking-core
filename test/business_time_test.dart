import 'package:nlevel_booking_core/nlevel_booking_core.dart';
import 'package:test/test.dart';

void main() {
  test('10:30 по Екатеринбургу - это 05:30 UTC', () {
    final moment = businessMoment(DateTime(2026, 8, 4), 10 * 60 + 30);
    expect(moment, DateTime.utc(2026, 8, 4, 5, 30));
  });

  test('минуты больше суток переходят на следующий день', () {
    final moment = businessMoment(DateTime(2026, 8, 4), 24 * 60 + 60);
    expect(moment, DateTime.utc(2026, 8, 4, 20, 0));
  });

  test('ранний слот попадает на предыдущие сутки в UTC', () {
    final moment = businessMoment(DateTime(2026, 8, 4), 3 * 60);
    expect(moment, DateTime.utc(2026, 8, 3, 22, 0));
  });

  test('результат не зависит от зоны устройства', () {
    final fromWallClock =
        businessMomentFromWallClock(DateTime(2026, 8, 4, 10, 30));
    expect(fromWallClock, businessMoment(DateTime(2026, 8, 4), 10 * 60 + 30));
    expect(fromWallClock.isUtc, isTrue);
  });
}
