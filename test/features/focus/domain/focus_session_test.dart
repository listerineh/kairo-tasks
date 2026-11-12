import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/features/focus/domain/focus_session.dart';

void main() {
  final t0 = DateTime(2026, 10, 21, 10);
  DateTime after(int minutes, [int seconds = 0]) =>
      t0.add(Duration(minutes: minutes, seconds: seconds));

  test('starts paused at a full focus round', () {
    const s = FocusSession();
    expect(s.running, isFalse);
    expect(s.remaining(t0), FocusSession.focusLength);
    expect(s.progress(t0), 0);
  });

  test('counts down from its end time, even across a background gap', () {
    final s = const FocusSession().start(t0);
    expect(s.remaining(after(10)), const Duration(minutes: 15));
    expect(s.progress(after(10)), closeTo(0.4, 1e-9));
    // The app slept for an hour: the round is simply over.
    expect(s.remaining(after(60)), Duration.zero);
    expect(s.finished(after(60)), isTrue);
  });

  test('pausing keeps what was left and resuming continues from it', () {
    final paused = const FocusSession().start(t0).pause(after(5));
    expect(paused.running, isFalse);
    expect(paused.remaining(after(30)), const Duration(minutes: 20));

    final resumed = paused.start(after(30));
    expect(resumed.remaining(after(40)), const Duration(minutes: 10));
  });

  test('+5 extends the phase whether running or paused', () {
    final running = const FocusSession().start(t0).addExtra(after(1));
    expect(running.remaining(after(1)), const Duration(minutes: 29));
    expect(running.total, const Duration(minutes: 30));

    final paused = const FocusSession().addExtra(t0);
    expect(paused.remaining(t0), const Duration(minutes: 30));
  });

  test('reset restarts the current phase, paused', () {
    final s = const FocusSession().start(t0).addExtra(t0).reset();
    expect(s.running, isFalse);
    expect(s.remaining(after(3)), FocusSession.focusLength);
  });

  test('rounds alternate with rests; the fourth rest is long', () {
    var s = const FocusSession();
    final rests = <Duration>[];
    for (var i = 0; i < FocusSession.rounds; i++) {
      s = s.next();
      expect(s.phase, FocusPhase.rest);
      rests.add(s.total);
      s = s.next();
      expect(s.phase, FocusPhase.focus);
    }
    expect(rests, [
      FocusSession.shortRest,
      FocusSession.shortRest,
      FocusSession.shortRest,
      FocusSession.longRest,
    ]);
    // After the long rest the cycle starts again.
    expect(s.round, 1);
  });
}
