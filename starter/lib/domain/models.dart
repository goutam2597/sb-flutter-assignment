enum DeliveryStatus { accepted, sent, delivered, failed }

class Money {
  const Money._(this.units, this.currency);
  final int units; // ten-thousandths of a currency unit
  final String currency;
  factory Money.parse(String value, String currency) {
    if (!RegExp(r'^\d+\.\d{4}$').hasMatch(value)) {
      throw FormatException('Money must have four decimals');
    }
    final p = value.split('.');
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw FormatException('Currency must be an ISO 4217 code');
    }
    return Money._(int.parse(p[0]) * 10000 + int.parse(p[1]), currency);
  }
  factory Money.zero(String currency) => Money._(0, currency);
  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add $currency and ${other.currency}');
    }
    return Money._(units + other.units, currency);
  }

  Money times(int count) => Money._(units * count, currency);
  String format() =>
      '$currency ${(units ~/ 10000)}.${(units % 10000).toString().padLeft(4, '0')}';
  @override
  bool operator ==(Object other) =>
      other is Money && other.units == units && other.currency == currency;
  @override
  int get hashCode => Object.hash(units, currency);
}

class Tenant {
  const Tenant(this.id, this.name);
  final String id;
  final String name;
}

class SendRequest {
  const SendRequest({required this.to, required this.body, this.referenceId});
  final String to;
  final String body;
  final String? referenceId;
}

class SendReceipt {
  const SendReceipt({
    required this.messageId,
    required this.provider,
    required this.status,
    required this.segmentCount,
    required this.cost,
    required this.currency,
  });
  final String messageId, provider, currency;
  final DeliveryStatus status;
  final int segmentCount;
  final Money cost;
}

class MessageRecord {
  const MessageRecord({
    required this.messageId,
    required this.recipient,
    required this.status,
    required this.segmentCount,
    required this.cost,
    required this.sentAt,
  });
  final String messageId, recipient;
  final DeliveryStatus status;
  final int segmentCount;
  final Money cost;
  final DateTime sentAt;
}

class MessagePage {
  const MessagePage(this.items, this.nextCursor);
  final List<MessageRecord> items;
  final String? nextCursor;
}

class CostRow {
  const CostRow(this.provider, this.totalCost, this.messageCount);
  final String provider;
  final Money totalCost;
  final int messageCount;
}

class CostBreakdown {
  const CostBreakdown(this.currency, this.totalCost, this.rows);
  final String currency;
  final Money totalCost;
  final List<CostRow> rows;
}

sealed class SmsFailure implements Exception {
  const SmsFailure(this.message);
  final String message;
}

class OfflineFailure extends SmsFailure {
  const OfflineFailure()
    : super('You appear to be offline. Check your connection and retry.');
}

class TimeoutFailure extends SmsFailure {
  const TimeoutFailure() : super('The request timed out. Please retry.');
}

class RateLimitFailure extends SmsFailure {
  const RateLimitFailure(this.retryAfter)
    : super('Sending is temporarily limited.');
  final Duration retryAfter;
}

class ProviderFailure extends SmsFailure {
  const ProviderFailure()
    : super('The SMS provider is unavailable. No message was sent.');
}

class SessionFailure extends SmsFailure {
  const SessionFailure() : super('Your session expired. Please sign in again.');
}

class ForbiddenFailure extends SmsFailure {
  const ForbiddenFailure() : super('You do not have access to this tenant.');
}

class UnauthorizedFailure extends SmsFailure {
  const UnauthorizedFailure() : super('The access token has expired.');
}

class ParsingFailure extends SmsFailure {
  const ParsingFailure() : super('The service returned an invalid response.');
}

class ValidationFailure extends SmsFailure {
  const ValidationFailure(super.message);
}
