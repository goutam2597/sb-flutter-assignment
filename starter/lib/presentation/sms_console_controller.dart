import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/logging/app_logger.dart';
import '../domain/models.dart';
import '../domain/sms_repository.dart';

class SmsConsoleState {
  const SmsConsoleState({
    required this.tenant,
    this.cost,
    this.history = const [],
    this.nextCursor,
    this.error,
    this.receipt,
    this.loading = true,
    this.sending = false,
    this.loadingMore = false,
    this.retryAfterSeconds = 0,
  });

  final Tenant tenant;
  final CostBreakdown? cost;
  final List<MessageRecord> history;
  final String? nextCursor;
  final String? error;
  final SendReceipt? receipt;
  final bool loading;
  final bool sending;
  final bool loadingMore;
  final int retryAfterSeconds;

  SmsConsoleState copyWith({
    Tenant? tenant,
    CostBreakdown? cost,
    bool clearCost = false,
    List<MessageRecord>? history,
    String? nextCursor,
    bool clearNextCursor = false,
    String? error,
    bool clearError = false,
    SendReceipt? receipt,
    bool clearReceipt = false,
    bool? loading,
    bool? sending,
    bool? loadingMore,
    int? retryAfterSeconds,
  }) => SmsConsoleState(
    tenant: tenant ?? this.tenant,
    cost: clearCost ? null : cost ?? this.cost,
    history: history ?? this.history,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    error: clearError ? null : error ?? this.error,
    receipt: clearReceipt ? null : receipt ?? this.receipt,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    loadingMore: loadingMore ?? this.loadingMore,
    retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
  );
}

class SmsConsoleCubit extends Cubit<SmsConsoleState> {
  SmsConsoleCubit(this.repository, {AppLogger? logger})
    : _logger = logger ?? AppLogger.instance,
      super(const SmsConsoleState(tenant: tenantsFirst));

  final SmsRepository repository;
  final AppLogger _logger;
  static const tenants = [tenantsFirst, Tenant('orbit', 'Orbit Retail')];
  static const tenantsFirst = Tenant('north', 'Northwind Health');

  int _generation = 0;
  Timer? _rateLimitTimer;

  Future<void> initialize() => refresh();

  Future<void> switchTenant(Tenant tenant) async {
    if (tenant.id == state.tenant.id) return;
    _logger.info(AppLogEvent.tenantChanged);
    _generation++;
    _rateLimitTimer?.cancel();
    emit(SmsConsoleState(tenant: tenant, loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    _logger.debug(AppLogEvent.refreshStarted);
    final generation = ++_generation;
    final tenantId = state.tenant.id;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final results = await Future.wait([
        repository.costs(tenantId),
        repository.messages(tenantId),
      ]);
      if (!_isCurrent(generation, tenantId)) return;
      final page = results[1] as MessagePage;
      emit(
        state.copyWith(
          cost: results[0] as CostBreakdown,
          history: List.unmodifiable(page.items),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          loading: false,
        ),
      );
      _logger.debug(AppLogEvent.refreshCompleted);
    } on SmsFailure catch (failure, stackTrace) {
      _logger.error(AppLogEvent.refreshFailed, failure, stackTrace);
      if (_isCurrent(generation, tenantId)) {
        emit(state.copyWith(error: failure.message, loading: false));
      }
    } catch (error, stackTrace) {
      _logger.error(AppLogEvent.refreshFailed, error, stackTrace);
      if (_isCurrent(generation, tenantId)) {
        emit(
          state.copyWith(
            error: 'Something went wrong. Please retry.',
            loading: false,
          ),
        );
      }
    }
  }

  Future<bool> send(String to, String body) async {
    if (state.sending || state.retryAfterSeconds > 0) return false;
    _logger.debug(AppLogEvent.sendStarted);
    final generation = _generation;
    final tenantId = state.tenant.id;
    emit(state.copyWith(sending: true, clearError: true, clearReceipt: true));
    try {
      final receipt = await repository.send(
        tenantId,
        SendRequest(to: to.trim(), body: body.trim()),
      );
      if (!_isCurrent(generation, tenantId)) return false;
      emit(state.copyWith(receipt: receipt));
      _logger.info(AppLogEvent.sendAccepted);
      await refresh();
      return true;
    } on RateLimitFailure catch (failure) {
      _logger.warning(AppLogEvent.sendRateLimited);
      if (_isCurrent(generation, tenantId)) {
        _startRateLimit(failure.retryAfter);
      }
    } on SmsFailure catch (failure, stackTrace) {
      _logger.error(AppLogEvent.sendRejected, failure, stackTrace);
      if (_isCurrent(generation, tenantId)) {
        emit(state.copyWith(error: failure.message));
      }
    } catch (error, stackTrace) {
      _logger.error(AppLogEvent.sendRejected, error, stackTrace);
      if (_isCurrent(generation, tenantId)) {
        emit(
          state.copyWith(error: 'The request did not complete. Please retry.'),
        );
      }
    } finally {
      if (!isClosed && tenantId == state.tenant.id && state.sending) {
        emit(state.copyWith(sending: false));
      }
    }
    return false;
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (state.loadingMore || cursor == null) return;
    _logger.debug(AppLogEvent.historyPageStarted);
    final generation = _generation;
    final tenantId = state.tenant.id;
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final page = await repository.messages(tenantId, cursor: cursor);
      if (!_isCurrent(generation, tenantId)) return;
      emit(
        state.copyWith(
          history: List.unmodifiable([...state.history, ...page.items]),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
      _logger.debug(AppLogEvent.historyPageCompleted);
    } on SmsFailure catch (failure, stackTrace) {
      _logger.error(AppLogEvent.historyPageFailed, failure, stackTrace);
      if (_isCurrent(generation, tenantId)) {
        emit(state.copyWith(error: failure.message, loadingMore: false));
      }
    } catch (error, stackTrace) {
      _logger.error(AppLogEvent.historyPageFailed, error, stackTrace);
      if (_isCurrent(generation, tenantId)) {
        emit(
          state.copyWith(
            error: 'Could not load more messages. Please retry.',
            loadingMore: false,
          ),
        );
      }
    }
  }

  bool _isCurrent(int generation, String tenantId) =>
      generation == _generation && tenantId == state.tenant.id && !isClosed;

  void _startRateLimit(Duration duration) {
    _rateLimitTimer?.cancel();
    var seconds = duration.inSeconds.clamp(1, 86400);
    emit(
      state.copyWith(
        error: 'Try again in $seconds seconds.',
        retryAfterSeconds: seconds,
      ),
    );
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;
      if (seconds <= 0) {
        timer.cancel();
        emit(state.copyWith(retryAfterSeconds: 0, clearError: true));
      } else {
        emit(
          state.copyWith(
            retryAfterSeconds: seconds,
            error: 'Try again in $seconds seconds.',
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _rateLimitTimer?.cancel();
    return super.close();
  }
}
