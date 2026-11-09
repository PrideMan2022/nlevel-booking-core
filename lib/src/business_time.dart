/// Время сервиса NLeveL.
///
/// Салон находится в Екатеринбурге: **UTC+5, без перехода на летнее время**.
///
/// В Firestore записи хранятся в двух видах:
///  * `date` + `slot` — «время салона» строками ('2026-08-04' + '10:30');
///  * `startAt` / `endAt` — абсолютный момент (Timestamp).
///
/// Раньше `startAt`/`endAt` считались через `DateTime(...)`, то есть в часовом
/// поясе устройства. На телефоне в Екатеринбурге это давало верный результат,
/// а на устройстве с другой зоной (клиент в поездке, браузер с чужой TZ)
/// абсолютный момент уезжал на разницу поясов. Напоминания от этого не
/// страдали — сервер считает их из `date` + `slot` и константы
/// BOOKING_TZ_OFFSET_MINUTES, — но кабинет клиента и сортировка админки
/// по `orderBy('startAt')` показывали сдвинутое время.
///
/// Здесь `startAt`/`endAt` считаются от фиксированного UTC+5, поэтому результат
/// не зависит от устройства. Для устройства в Екатеринбурге значение
/// в точности совпадает с прежним — поведение не меняется.
///
/// Значение обязано совпадать со смещением, которое использует серверная
/// часть при расчёте напоминаний (300 минут = UTC+5).
library;

/// Смещение часового пояса сервиса относительно UTC.
const Duration kBusinessUtcOffset = Duration(hours: 5);

/// Абсолютный момент по «времени салона»: день + минуты от полуночи.
///
/// `minutesFromMidnight` может быть больше 1440 — переход на следующий день
/// обрабатывается корректно (арифметика в UTC, без DST).
DateTime businessMoment(DateTime day, int minutesFromMidnight) {
  return DateTime.utc(day.year, day.month, day.day)
      .add(Duration(minutes: minutesFromMidnight))
      .subtract(kBusinessUtcOffset);
}

/// Перевод «настенного» DateTime в корректный абсолютный момент.
///
/// Используется там, где значение уже построено как время салона
/// (например, результат `planEndAt`), но в зоне устройства.
/// Поля даты и времени берутся как есть, зона — всегда UTC+5.
DateTime businessMomentFromWallClock(DateTime wallClock) {
  return DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
  ).subtract(kBusinessUtcOffset);
}
