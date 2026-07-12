import '../core/logging/app_logger.dart';
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
  RefreshingSmsRepository(this.inner, this.refresher, {AppLogger? logger})
    : _logger = logger ?? AppLogger.instance;
  final SmsRepository inner;
  final TokenRefresher refresher;
  final AppLogger _logger;

  Future<T> _once<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on UnauthorizedFailure {
      _logger.info(AppLogEvent.tokenRefreshStarted);
      if (!await refresher.refresh()) {
        _logger.warning(AppLogEvent.sessionExpired);
        throw const SessionFailure();
      }
      _logger.info(AppLogEvent.tokenRefreshCompleted);
      try {
        return await operation();
      } on UnauthorizedFailure {
        _logger.warning(AppLogEvent.sessionExpired);
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
