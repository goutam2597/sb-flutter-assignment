import 'models.dart';

abstract interface class SmsRepository {
  Future<SendReceipt> send(String tenantId, SendRequest request);
  Future<CostBreakdown> costs(String tenantId);
  Future<MessagePage> messages(
    String tenantId, {
    String? cursor,
    int limit = 50,
  });
}

abstract interface class TokenRefresher {
  Future<bool> refresh();
}

/// Retries an unauthorized call once and never exposes or logs credentials.
class RefreshingSmsRepository implements SmsRepository {
  RefreshingSmsRepository(this.inner, this.refresher);
  final SmsRepository inner;
  final TokenRefresher refresher;

  Future<T> _once<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on UnauthorizedFailure {
      if (!await refresher.refresh()) throw const SessionFailure();
      try {
        return await operation();
      } on UnauthorizedFailure {
        throw const SessionFailure();
      }
    }
  }

  @override
  Future<SendReceipt> send(String tenantId, SendRequest request) =>
      _once(() => inner.send(tenantId, request));
  @override
  Future<CostBreakdown> costs(String tenantId) =>
      _once(() => inner.costs(tenantId));
  @override
  Future<MessagePage> messages(
    String tenantId, {
    String? cursor,
    int limit = 50,
  }) => _once(() => inner.messages(tenantId, cursor: cursor, limit: limit));
}
