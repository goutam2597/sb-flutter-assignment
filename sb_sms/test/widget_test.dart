import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sb_sms/app.dart';
import 'package:sb_sms/data/fake_sms_repository.dart';
import 'package:sb_sms/domain/models.dart';

void main() {
  testWidgets('invalid recipient shows a useful validation error', (
    tester,
  ) async {
    await tester.pumpWidget(
      SmsApp(repository: FakeSmsRepository(delay: Duration.zero)),
    );
    await tester.pumpAndSettle();
    
    final fab = find.byType(FloatingActionButton);
    if (tester.any(fab)) {
      await tester.tap(fab);
      await tester.pumpAndSettle();
    }
    
    await tester.enterText(find.byType(TextFormField).first, '123');
    await tester.enterText(find.byType(TextFormField).last, 'Hello');
    await tester.ensureVisible(find.text('Send SMS'));
    await tester.tap(find.text('Send SMS'));
    await tester.pump();
    expect(find.text('Use international E.164 format'), findsOneWidget);
  });

  testWidgets('provider failure stops progress and allows retry', (
    tester,
  ) async {
    final repository = FakeSmsRepository(delay: Duration.zero);
    await tester.pumpWidget(SmsApp(repository: repository));
    await tester.pumpAndSettle();
    repository.failure = const ProviderFailure();
    
    final fab = find.byType(FloatingActionButton);
    if (tester.any(fab)) {
      await tester.tap(fab);
      await tester.pumpAndSettle();
    }
    
    await tester.enterText(find.byType(TextFormField).first, '+4915112345678');
    await tester.enterText(find.byType(TextFormField).last, 'Hello');
    await tester.ensureVisible(find.text('Send SMS'));
    await tester.tap(find.text('Send SMS'));
    await tester.pumpAndSettle();
    expect(find.textContaining('provider is unavailable'), findsOneWidget);
    expect(find.text('Send SMS'), findsOneWidget);
  });

  testWidgets('successful send is described as accepted, not delivered', (
    tester,
  ) async {
    await tester.pumpWidget(
      SmsApp(repository: FakeSmsRepository(delay: Duration.zero)),
    );
    await tester.pumpAndSettle();
    
    final fab = find.byType(FloatingActionButton);
    if (tester.any(fab)) {
      await tester.tap(fab);
      await tester.pumpAndSettle();
    }
    
    await tester.enterText(find.byType(TextFormField).first, '+4915112345678');
    await tester.enterText(find.byType(TextFormField).last, 'Hello');
    await tester.ensureVisible(find.text('Send SMS'));
    await tester.tap(find.text('Send SMS'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Accepted by TWILIO'), findsOneWidget);
    expect(find.textContaining('Delivery is still pending'), findsOneWidget);
  });
}
