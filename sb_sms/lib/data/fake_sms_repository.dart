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
    'north': List.generate(30, (i) {
      final hour = 12 - (i % 12);
      final day = 12 - (i ~/ 12);
      final isFailed = i % 7 == 0;
      final segmentCount = (i % 3) + 1;
      return MessageRecord(
        messageId: 'SMNO${(i + 1).toString().padLeft(3, '0')}',
        recipient: '+4915*****${700 + i}',
        status: isFailed ? DeliveryStatus.failed : DeliveryStatus.delivered,
        segmentCount: segmentCount,
        cost: Money.parse((0.0750 * segmentCount).toStringAsFixed(4), 'EUR'),
        sentAt: DateTime.utc(2026, 7, day, hour, 0),
      );
    }),
    'orbit': List.generate(30, (i) {
      final hour = 16 - (i % 12);
      final day = 12 - (i ~/ 12);
      final isFailed = i % 5 == 0;
      final segmentCount = (i % 2) + 1;
      return MessageRecord(
        messageId: 'SMOR${(i + 1).toString().padLeft(3, '0')}',
        recipient: '+4915*****${800 + i}',
        status: isFailed ? DeliveryStatus.failed : DeliveryStatus.delivered,
        segmentCount: segmentCount,
        cost: Money.parse((0.0750 * segmentCount).toStringAsFixed(4), 'EUR'),
        sentAt: DateTime.utc(2026, 7, day, hour, 30),
      );
    }),
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
