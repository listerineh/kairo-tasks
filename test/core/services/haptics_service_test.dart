import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairotasks/core/services/haptics_service.dart';

void main() {
  final calls = <Object?>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('maps each intent to its haptic', () async {
    final haptics = HapticsService();

    await haptics.selection();
    await haptics.completed();
    await haptics.celebrated();

    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  test('stays silent when the user turns haptics off', () async {
    final haptics = HapticsService()..enabled.value = false;

    await haptics.selection();
    await haptics.completed();

    expect(calls, isEmpty);
  });
}
