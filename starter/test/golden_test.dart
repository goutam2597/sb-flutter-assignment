@Tags(['golden'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app.dart';
import 'package:starter/data/fake_sms_repository.dart';

void main() {
  testWidgets('360px loaded light theme', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SmsApp(repository: FakeSmsRepository(delay: Duration.zero)),
    );
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(SmsApp),
      matchesGoldenFile('goldens/sms_console_360_light.png'),
    );
  });
}
