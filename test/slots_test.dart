import 'package:nlevel_booking_core/nlevel_booking_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeSlot', () {
    test('приводит разные записи к HH:mm', () {
      expect(NLevelTime.normalizeSlot('9:5'), '09:05');
      expect(NLevelTime.normalizeSlot('10.30'), '10:30');
      expect(NLevelTime.normalizeSlot(' 10 : 30 '), '10:30');
      expect(NLevelTime.normalizeSlot('10:30 '), '10:30');
    });

    test('не округляет минуты и ограничивает диапазон', () {
      expect(NLevelTime.normalizeSlot('10:45'), '10:45');
      expect(NLevelTime.normalizeSlot('99:99'), '23:59');
    });

    test('мусор превращается в 00:00', () {
      expect(NLevelTime.normalizeSlot('утро'), '00:00');
      expect(NLevelTime.normalizeSlot(''), '00:00');
    });
  });

  group('конвертация времени', () {
    test('туда и обратно', () {
      expect(NLevelTime.timeToMinutes('20:30'), 1230);
      expect(NLevelTime.minutesToTime(1230), '20:30');
      expect(NLevelTime.minutesToTime(-5), '00:00');
    });

    test('dateKeyToLocalDate не зависит от часового пояса', () {
      final d = NLevelTime.dateKeyToLocalDate('2026-08-04');
      expect([d.year, d.month, d.day, d.hour], [2026, 8, 4, 0]);
      expect(d.isUtc, isFalse);
    });

    test('dateKey дополняет нулями', () {
      expect(NLevelTime.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  test('сетка начал: 10:00 ... 20:30, 22 слота', () {
    final slots = NLevelTime.generateDayStartSlots();
    expect(slots.first, '10:00');
    expect(slots.last, '20:30');
    expect(slots, hasLength(22));
  });

  group('buildPlan', () {
    // 2026-08-04 - вторник, 2026-08-08 - суббота, 2026-08-09 - воскресенье.
    test('короткая работа занимает один слот', () {
      final plan = NLevelTime.buildPlan(
        startDate: DateTime(2026, 8, 4),
        startSlot: '10:00',
        durationMinutes: 20,
      );
      expect(plan, [const SlotSegment('2026-08-04', '10:00')]);
    });

    test('2 часа раскладываются на 4 подряд идущих слота', () {
      final plan = NLevelTime.buildPlan(
        startDate: DateTime(2026, 8, 4),
        startSlot: '13:00',
        durationMinutes: 120,
      );
      expect(plan.map((s) => s.slot), ['13:00', '13:30', '14:00', '14:30']);
    });

    test('метка вне сетки подтягивается вперёд, не назад', () {
      final plan = NLevelTime.buildPlan(
        startDate: DateTime(2026, 8, 4),
        startSlot: '10:10',
        durationMinutes: 30,
      );
      expect(plan.single.slot, '10:30');
    });

    test('работа переходит на следующий день в 10:00', () {
      final plan = NLevelTime.buildPlan(
        startDate: DateTime(2026, 8, 4),
        startSlot: '20:00',
        durationMinutes: 120,
      );
      expect(plan, const [
        SlotSegment('2026-08-04', '20:00'),
        SlotSegment('2026-08-04', '20:30'),
        SlotSegment('2026-08-05', '10:00'),
        SlotSegment('2026-08-05', '10:30'),
      ]);
    });

    test('воскресенье пропускается при переносе', () {
      final plan = NLevelTime.buildPlan(
        startDate: DateTime(2026, 8, 8),
        startSlot: '20:30',
        durationMinutes: 60,
      );
      expect(plan, const [
        SlotSegment('2026-08-08', '20:30'),
        SlotSegment('2026-08-10', '10:00'),
      ]);
    });

    test('старт в воскресенье переезжает на понедельник с тем же временем', () {
      final plan = NLevelTime.buildPlan(
        startDate: DateTime(2026, 8, 9),
        startSlot: '15:00',
        durationMinutes: 60,
      );
      expect(plan, const [
        SlotSegment('2026-08-10', '15:00'),
        SlotSegment('2026-08-10', '15:30'),
      ]);
    });

    test('время раньше открытия поднимается до 10:00', () {
      final plan = NLevelTime.buildPlan(
        startDate: DateTime(2026, 8, 4),
        startSlot: '07:00',
        durationMinutes: 30,
      );
      expect(plan.single.slot, '10:00');
    });

    test('нулевая и отрицательная длительность дают один слот', () {
      for (final minutes in [0, -30]) {
        final plan = NLevelTime.buildPlan(
          startDate: DateTime(2026, 8, 4),
          startSlot: '12:00',
          durationMinutes: minutes,
        );
        expect(plan, hasLength(1));
      }
    });
  });

  group('planEndAt', () {
    test('конец равен началу последнего слота плюс 30 минут', () {
      final end = NLevelTime.planEndAt(
        startDate: DateTime(2026, 8, 4),
        startSlot: '13:00',
        durationMinutes: 120,
      );
      expect(end, DateTime(2026, 8, 4, 15, 0));
    });

    test('учитывает перенос через ночь и воскресенье', () {
      final end = NLevelTime.planEndAt(
        startDate: DateTime(2026, 8, 8),
        startSlot: '20:30',
        durationMinutes: 60,
      );
      expect(end, DateTime(2026, 8, 10, 10, 30));
    });
  });
}
