import 'dart:async';
import '../domain/models.dart';
import '../domain/sms_repository.dart';

class FakeSmsRepository implements SmsRepository {
  FakeSmsRepository({
    this.delay = const Duration(milliseconds: 350),
    this.failure,
  });
  final Duration delay;
  SmsFailure? failure;
  final Map<String, List<MessageRecord>> _records = {};
  final Map<String, int> _cursors = {};
  Future<T> _bounded<T>(T Function() work) =>
      Future<T>.delayed(delay, work).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw const OfflineFailure(),
      );
  List<MessageRecord> _for(String tenant) => _records.putIfAbsent(
    tenant,
    () => List.generate(
      7,
      (i) => MessageRecord(
        messageId: 'SM${tenant.substring(0, 2).toUpperCase()}00$i',
        recipient: '+4915*****${70 + i}',
        status: i == 0 ? DeliveryStatus.sent : DeliveryStatus.delivered,
        segmentCount: i.isEven ? 1 : 2,
        cost: Money.parse(i.isEven ? '0.0750' : '0.1500', 'EUR'),
        sentAt: DateTime.now().toUtc().subtract(Duration(hours: i * 7)),
      ),
    ),
  );
  @override
  Future<CostBreakdown> costs(String tenantId) => _bounded(() {
    if (failure case final value?) throw value;
    final rows = _for(tenantId);
    var total = Money.zero('EUR');
    for (final m in rows) {
      total += m.cost;
    }
    return CostBreakdown('EUR', total, [CostRow('TWILIO', total, rows.length)]);
  });
  @override
  Future<MessagePage> messages(
    String tenantId, {
    String? cursor,
    int limit = 50,
  }) => _bounded(() {
    if (failure case final value?) throw value;
    final all = _for(tenantId);
    if (cursor != null && !_cursors.containsKey(cursor)) {
      throw const ParsingFailure();
    }
    final start = cursor == null ? 0 : _cursors[cursor]!;
    final end = (start + limit).clamp(0, all.length);
    final next = end < all.length ? 'cursor-${tenantId.hashCode}-$end' : null;
    if (next != null) _cursors[next] = end;
    return MessagePage(List.unmodifiable(all.sublist(start, end)), next);
  });
  @override
  Future<SendReceipt> send(String tenantId, SendRequest request) =>
      _bounded(() {
        if (failure case final value?) throw value;
        if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(request.to)) {
          throw const ValidationFailure(
            'Enter a valid E.164 number, for example +4915112345678.',
          );
        }
        if (request.body.trim().isEmpty) {
          throw const ValidationFailure('Enter a message.');
        }
        if (request.body.length > 320) {
          throw const ValidationFailure(
            'Message must be 320 characters or fewer.',
          );
        }
        final segments = request.body.length > 160 ? 2 : 1;
        final cost = Money.parse('0.0750', 'EUR').times(segments);
        final id = 'SM${DateTime.now().microsecondsSinceEpoch}';
        _for(tenantId).insert(
          0,
          MessageRecord(
            messageId: id,
            recipient: _mask(request.to),
            status: DeliveryStatus.accepted,
            segmentCount: segments,
            cost: cost,
            sentAt: DateTime.now().toUtc(),
          ),
        );
        return SendReceipt(
          messageId: id,
          provider: 'TWILIO',
          status: DeliveryStatus.accepted,
          segmentCount: segments,
          cost: cost,
          currency: 'EUR',
        );
      });
  String _mask(String value) =>
      '${value.substring(0, 5)}*****${value.substring(value.length - 2)}';
}
