import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/domain/models.dart';
import 'package:starter/domain/sms_repository.dart';
import 'package:starter/presentation/sms_console_controller.dart';

class _TenantRaceRepository implements SmsRepository {
  final a = Completer<MessagePage>();
  @override
  Future<CostBreakdown> costs(String tenantId) async =>
      CostBreakdown('EUR', Money.zero('EUR'), const []);
  @override
  Future<MessagePage> messages(
    String tenantId, {
    String? cursor,
    int limit = 50,
  }) {
    if (tenantId == 'north') return a.future;
    return Future.value(
      MessagePage([
        MessageRecord(
          messageId: 'ORBIT',
          recipient: '+4915*****78',
          status: DeliveryStatus.delivered,
          segmentCount: 1,
          cost: Money.parse('0.0750', 'EUR'),
          sentAt: DateTime.utc(2026),
        ),
      ], null),
    );
  }

  @override
  Future<SendReceipt> send(String tenantId, SendRequest request) =>
      throw UnimplementedError();
}

class _SendSpyRepository implements SmsRepository {
  final sendCompleter = Completer<SendReceipt>();
  int sendCalls = 0;

  @override
  Future<CostBreakdown> costs(String tenantId) async =>
      CostBreakdown('EUR', Money.zero('EUR'), const []);

  @override
  Future<MessagePage> messages(
    String tenantId, {
    String? cursor,
    int limit = 50,
  }) async => const MessagePage([], null);

  @override
  Future<SendReceipt> send(String tenantId, SendRequest request) {
    sendCalls++;
    return sendCompleter.future;
  }
}

void main() {
  test('slow tenant A cannot overwrite tenant B state', () async {
    final repository = _TenantRaceRepository();
    final cubit = SmsConsoleCubit(repository);
    unawaited(cubit.initialize());
    await cubit.switchTenant(SmsConsoleCubit.tenants.last);
    repository.a.complete(
      MessagePage([
        MessageRecord(
          messageId: 'NORTH',
          recipient: '+4915*****70',
          status: DeliveryStatus.delivered,
          segmentCount: 1,
          cost: Money.parse('0.0750', 'EUR'),
          sentAt: DateTime.utc(2026),
        ),
      ], null),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.tenant.id, 'orbit');
    expect(cubit.state.history.single.messageId, 'ORBIT');
    await cubit.close();
  });

  test(
    'rapid duplicate sends create only one billable repository call',
    () async {
      final repository = _SendSpyRepository();
      final cubit = SmsConsoleCubit(repository);
      await cubit.initialize();
      final first = cubit.send('+4915112345678', 'Hello');
      final second = await cubit.send('+4915112345678', 'Hello');
      expect(second, isFalse);
      expect(repository.sendCalls, 1);
      repository.sendCompleter.complete(
        SendReceipt(
          messageId: 'SM1',
          provider: 'TWILIO',
          status: DeliveryStatus.accepted,
          segmentCount: 1,
          cost: Money.parse('0.0750', 'EUR'),
          currency: 'EUR',
        ),
      );
      expect(await first, isTrue);
      expect(cubit.state.sending, isFalse);
      await cubit.close();
    },
  );
}
