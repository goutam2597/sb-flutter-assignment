import 'package:flutter_test/flutter_test.dart';
import 'package:sb_sms/data/fake_sms_repository.dart';
import 'package:sb_sms/domain/models.dart';
import 'package:sb_sms/domain/sms_repository.dart';

class _UnauthorizedRepository implements SmsRepository {
  int calls = 0;
  @override
  Future<CostBreakdown> costs(String tenantId) async =>
      throw UnimplementedError();
  @override
  Future<MessagePage> messages(
    String tenantId, {
    String? cursor,
    int limit = 50,
  }) async => throw UnimplementedError();
  @override
  Future<SendReceipt> send(String tenantId, SendRequest request) async {
    calls++;
    if (calls == 1) throw const UnauthorizedFailure();
    return SendReceipt(
      messageId: 'SM1',
      provider: 'TWILIO',
      status: DeliveryStatus.accepted,
      segmentCount: 1,
      cost: Money.parse('0.0750', 'EUR'),
      currency: 'EUR',
    );
  }
}

class _Refresher implements TokenRefresher {
  _Refresher(this.result);
  final bool result;
  int calls = 0;
  @override
  Future<bool> refresh() async {
    calls++;
    return result;
  }
}

void main() {
  test('opaque history cursor is passed back unchanged', () async {
    final repository = FakeSmsRepository(delay: Duration.zero);
    final first = await repository.messages('north', limit: 2);
    expect(first.nextCursor, startsWith('cursor-'));
    final second = await repository.messages(
      'north',
      cursor: first.nextCursor,
      limit: 2,
    );
    expect(second.items.first.messageId, isNot(first.items.first.messageId));
  });

  test('expired access token refreshes and retries exactly once', () async {
    final inner = _UnauthorizedRepository();
    final refresher = _Refresher(true);
    final repository = RefreshingSmsRepository(inner, refresher);
    await repository.send(
      'north',
      const SendRequest(to: '+4915112345678', body: 'Hi'),
    );
    expect(inner.calls, 2);
    expect(refresher.calls, 1);
  });

  test('refresh failure becomes session failure without a loop', () async {
    final inner = _UnauthorizedRepository();
    final refresher = _Refresher(false);
    final repository = RefreshingSmsRepository(inner, refresher);
    await expectLater(
      repository.send(
        'north',
        const SendRequest(to: '+4915112345678', body: 'Hi'),
      ),
      throwsA(isA<SessionFailure>()),
    );
    expect(inner.calls, 1);
    expect(refresher.calls, 1);
  });
}
