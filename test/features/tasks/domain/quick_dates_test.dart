import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/tasks/domain/quick_dates.dart';

void main() {
  // 2026-10-20 is a Tuesday.
  final tuesday = DateTime(2026, 10, 20, 15, 30);

  test('today and tomorrow are midnights', () {
    expect(quickDate(QuickDate.today, tuesday), DateTime(2026, 10, 20));
    expect(quickDate(QuickDate.tomorrow, tuesday), DateTime(2026, 10, 21));
  });

  test('this weekend is the coming Saturday', () {
    expect(quickDate(QuickDate.weekend, tuesday), DateTime(2026, 10, 24));
    expect(
      quickDate(QuickDate.weekend, DateTime(2026, 10, 23, 22)),
      DateTime(2026, 10, 24),
    );
  });

  test('during the weekend it is that same day', () {
    expect(
      quickDate(QuickDate.weekend, DateTime(2026, 10, 24, 9)),
      DateTime(2026, 10, 24),
    );
    expect(
      quickDate(QuickDate.weekend, DateTime(2026, 10, 25, 9)),
      DateTime(2026, 10, 25),
    );
  });

  test('crosses month ends', () {
    expect(
      quickDate(QuickDate.tomorrow, DateTime(2026, 10, 31)),
      DateTime(2026, 11, 1),
    );
    expect(
      quickDate(QuickDate.weekend, DateTime(2026, 12, 29)),
      DateTime(2027, 1, 2),
    );
  });

  test('recognizes which shortcut a date matches', () {
    expect(
      matchingQuickDate(DateTime(2026, 10, 21, 9), tuesday),
      QuickDate.tomorrow,
    );
    expect(
      matchingQuickDate(DateTime(2026, 10, 24), tuesday),
      QuickDate.weekend,
    );
    expect(matchingQuickDate(DateTime(2026, 11, 2), tuesday), isNull);
    expect(matchingQuickDate(null, tuesday), isNull);
  });

  test('on a Saturday, today wins over the weekend', () {
    final saturday = DateTime(2026, 10, 24, 10);
    expect(
      matchingQuickDate(DateTime(2026, 10, 24), saturday),
      QuickDate.today,
    );
  });

  test('withTime and hasTimeOfDay', () {
    final day = DateTime(2026, 10, 20);
    expect(withTime(day, (hour: 9, minute: 30)), DateTime(2026, 10, 20, 9, 30));
    expect(withTime(DateTime(2026, 10, 20, 18), null), day);
    expect(hasTimeOfDay(day), isFalse);
    expect(hasTimeOfDay(DateTime(2026, 10, 20, 0, 1)), isTrue);
  });
}
