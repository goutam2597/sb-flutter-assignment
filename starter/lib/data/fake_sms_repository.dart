import 'dart:async';
import '../core/logging/app_logger.dart';
import '../domain/models.dart';
import '../domain/sms_repository.dart';

class FakeSmsRepository implements SmsRepository {
  FakeSmsRepository({
    this.delay = const Duration(milliseconds: 350),
    this.failure,
    AppLogger? logger,
  }) : _logger = logger ?? AppLogger.instance;
  final Duration delay;
  SmsFailure? failure;
  final AppLogger _logger;
  final Map<String, List<MessageRecord>> _records = {};
  final Map<String, int> _cursors = {};
  Future<T> _bounded<T>(T Function() work) async {
    _logger.debug(AppLogEvent.fakeRequestStarted);
    try {
      final result = await Future<T>.delayed(delay, work).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw const OfflineFailure(),
      );
      _logger.debug(AppLogEvent.fakeRequestCompleted);
      return result;
    } catch (error, stackTrace) {
      _logger.error(AppLogEvent.fakeRequestFailed, error, stackTrace);
      rethrow;
    }
  }

  // Hardcoded seed data so each tenant shows genuinely different data.
  // 'north' = Northwind Health: 12 messages, mix of delivered/failed/sent, high spend.
  // 'orbit' = Orbit Retail: 5 messages, mostly delivered, low spend.
  static final Map<String, List<MessageRecord>> _seeds = {
    'north': [
      MessageRecord(messageId: 'SMNO001', recipient: '+4915*****701', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 10, 0)),
      MessageRecord(messageId: 'SMNO002', recipient: '+4915*****702', status: DeliveryStatus.delivered, segmentCount: 2, cost: Money.parse('0.1500', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 9, 0)),
      MessageRecord(messageId: 'SMNO003', recipient: '+4915*****703', status: DeliveryStatus.failed,    segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 8, 0)),
      MessageRecord(messageId: 'SMNO004', recipient: '+4915*****704', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 7, 0)),
      MessageRecord(messageId: 'SMNO005', recipient: '+4915*****705', status: DeliveryStatus.delivered, segmentCount: 2, cost: Money.parse('0.1500', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 6, 0)),
      MessageRecord(messageId: 'SMNO006', recipient: '+4915*****706', status: DeliveryStatus.failed,    segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 5, 0)),
      MessageRecord(messageId: 'SMNO007', recipient: '+4915*****707', status: DeliveryStatus.sent,      segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 4, 0)),
      MessageRecord(messageId: 'SMNO008', recipient: '+4915*****708', status: DeliveryStatus.delivered, segmentCount: 2, cost: Money.parse('0.1500', 'EUR'), sentAt: DateTime.utc(2026, 7, 11, 18, 0)),
      MessageRecord(messageId: 'SMNO009', recipient: '+4915*****709', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 11, 12, 0)),
      MessageRecord(messageId: 'SMNO010', recipient: '+4915*****710', status: DeliveryStatus.failed,    segmentCount: 2, cost: Money.parse('0.1500', 'EUR'), sentAt: DateTime.utc(2026, 7, 11, 8, 0)),
      MessageRecord(messageId: 'SMNO011', recipient: '+4915*****711', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 10, 20, 0)),
      MessageRecord(messageId: 'SMNO012', recipient: '+4915*****712', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 10, 14, 0)),
    ],
    'orbit': [
      MessageRecord(messageId: 'SMOR001', recipient: '+4915*****801', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 11, 0)),
      MessageRecord(messageId: 'SMOR002', recipient: '+4915*****802', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 8, 30)),
      MessageRecord(messageId: 'SMOR003', recipient: '+4915*****803', status: DeliveryStatus.failed,    segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 12, 6, 0)),
      MessageRecord(messageId: 'SMOR004', recipient: '+4915*****804', status: DeliveryStatus.delivered, segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 11, 22, 0)),
      MessageRecord(messageId: 'SMOR005', recipient: '+4915*****805', status: DeliveryStatus.sent,      segmentCount: 1, cost: Money.parse('0.0750', 'EUR'), sentAt: DateTime.utc(2026, 7, 11, 16, 0)),
    ],
  };

  List<MessageRecord> _for(String tenant) => _records.putIfAbsent(
    tenant,
    () => List.of(_seeds[tenant] ?? _seeds['north']!),
  );

  @override
  Future<CostBreakdown> costs(String tenantId) => _bounded(() {
    if (failure case final value?) throw value;
    final rows = _for(tenantId);
    var total = Money.zero('EUR');
    for (final m in rows) {
      total += m.cost;
    }
    final provider = tenantId == 'orbit' ? 'VONAGE' : 'TWILIO';
    return CostBreakdown('EUR', total, [CostRow(provider, total, rows.length)]);
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
