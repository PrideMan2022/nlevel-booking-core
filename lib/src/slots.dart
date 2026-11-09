/// Сетка записи на 30 минут: разбор меток времени и раскладка длинных работ
/// по слотам с переносом на следующий день и пропуском воскресений.
library;

/// Один 30-минутный сегмент записи: дата `yyyy-MM-dd` и начало слота `HH:mm`.
class SlotSegment {
  final String date;
  final String slot;

  const SlotSegment(this.date, this.slot);

  @override
  bool operator ==(Object other) =>
      other is SlotSegment && other.date == date && other.slot == slot;

  @override
  int get hashCode => Object.hash(date, slot);

  @override
  String toString() => '$date $slot';
}

class NLevelTime {
  const NLevelTime._();

  static const int slotStepMinutes = 30;
  static const int openMin = 10 * 60;
  static const int closeMin = 21 * 60;
  static const int lastStartMin = closeMin - slotStepMinutes;

  static bool isSunday(DateTime d) => d.weekday == DateTime.sunday;

  static final RegExp _slotPattern = RegExp(r'^(\d{1,2})\s*:\s*(\d{1,2})');

  /// Приводит метку вида `H:mm`, `HH.mm` или `10 : 30` к строгому `HH:mm`.
  /// Минуты не округляются. Нераспознанное значение даёт `00:00`.
  static String normalizeSlot(String raw) {
    // Неразрывные пробелы попадают в строку при копировании из интерфейса.
    final cleaned =
        raw.replaceAll(RegExp(r'[  ]'), ' ').trim().replaceAll('.', ':');
    final match = _slotPattern.firstMatch(cleaned);
    if (match == null) return '00:00';
    final hours = (int.tryParse(match.group(1)!) ?? 0).clamp(0, 23);
    final minutes = (int.tryParse(match.group(2)!) ?? 0).clamp(0, 59);
    return minutesToTime(hours * 60 + minutes);
  }

  static int timeToMinutes(String label) {
    final parts = normalizeSlot(label).split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String minutesToTime(int minutes) {
    final m = minutes < 0 ? 0 : minutes;
    return '${_two(m ~/ 60)}:${_two(m % 60)}';
  }

  /// `DateTime.parse('2026-08-04')` считает дату без времени UTC-полуночью,
  /// поэтому на устройстве западнее UTC день сдвигается. Здесь дата локальная.
  static DateTime dateKeyToLocalDate(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return DateTime(1970);
    return DateTime(
      int.tryParse(parts[0]) ?? 1970,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  /// Все допустимые начала работ за день: 10:00, 10:30 ... 20:30.
  static List<String> generateDayStartSlots() => [
        for (var t = openMin; t <= lastStartMin; t += slotStepMinutes)
          minutesToTime(t),
      ];

  /// Раскладывает работу длительностью [durationMinutes] по получасовым
  /// сегментам, начиная с [startSlot] в день [startDate].
  ///
  /// * Метка вне сетки подтягивается вперёд к ближайшему слоту, назад — никогда.
  /// * После закрытия салона работа продолжается в 10:00 следующего дня.
  /// * Воскресенья пропускаются. Если сам [startDate] воскресенье,
  ///   запись переезжает на понедельник с тем же временем начала.
  static List<SlotSegment> buildPlan({
    required DateTime startDate,
    required String startSlot,
    required int durationMinutes,
  }) {
    final count = (durationMinutes / slotStepMinutes).ceil().clamp(1, 10000);

    var day = DateTime(startDate.year, startDate.month, startDate.day);
    var cursor = _snapToGrid(timeToMinutes(startSlot));
    if (cursor < openMin) cursor = openMin;

    while (isSunday(day)) {
      day = _nextDay(day);
    }

    final segments = <SlotSegment>[];
    for (var i = 0; i < count; i++) {
      if (cursor >= closeMin) {
        day = _nextDay(day);
        while (isSunday(day)) {
          day = _nextDay(day);
        }
        cursor = openMin;
      }
      segments.add(SlotSegment(dateKey(day), minutesToTime(cursor)));
      cursor += slotStepMinutes;
    }
    return segments;
  }

  /// Момент окончания работы в «настенном» времени салона.
  static DateTime planEndAt({
    required DateTime startDate,
    required String startSlot,
    required int durationMinutes,
  }) {
    final last = buildPlan(
      startDate: startDate,
      startSlot: startSlot,
      durationMinutes: durationMinutes,
    ).last;
    final day = dateKeyToLocalDate(last.date);
    final end = timeToMinutes(last.slot) + slotStepMinutes;
    return DateTime(day.year, day.month, day.day, end ~/ 60, end % 60);
  }

  static int _snapToGrid(int minutes) =>
      (minutes + slotStepMinutes - 1) ~/ slotStepMinutes * slotStepMinutes;

  static DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  static String _two(int n) => n.toString().padLeft(2, '0');
}
