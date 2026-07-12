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

void main() {
  test('slow tenant A cannot overwrite tenant B state', () async {
    final repository = _TenantRaceRepository();
    final controller = SmsConsoleController(repository);
    unawaited(controller.initialize());
    await controller.switchTenant(SmsConsoleController.tenants.last);
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
    expect(controller.tenant.id, 'orbit');
    expect(controller.history.single.messageId, 'ORBIT');
  });
}
