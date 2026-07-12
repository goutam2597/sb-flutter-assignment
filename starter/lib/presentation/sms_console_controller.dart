import 'dart:async';

import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../domain/sms_repository.dart';

class SmsConsoleController extends ChangeNotifier {
  SmsConsoleController(this.repository);
  final SmsRepository repository;
  static const tenants = [
    Tenant('north', 'Northwind Health'),
    Tenant('orbit', 'Orbit Retail'),
  ];
  Tenant tenant = tenants.first;
  CostBreakdown? cost;
  List<MessageRecord> history = [];
  String? nextCursor, error;
  SendReceipt? receipt;
  bool loading = true, sending = false, loadingMore = false;
  DateTime? _rateLimitedUntil;
  Timer? _rateLimitTimer;
  int get retryAfterSeconds {
    final until = _rateLimitedUntil;
    if (until == null) return 0;
    return (until.difference(DateTime.now()).inSeconds + 1).clamp(0, 86400);
  }

  int _generation = 0;
  Future<void> initialize() => refresh();
  Future<void> switchTenant(Tenant value) async {
    if (value.id == tenant.id) return;
    tenant = value;
    _generation++;
    cost = null;
    history = [];
    nextCursor = null;
    receipt = null;
    error = null;
    loading = true;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    final g = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        repository.costs(tenant.id),
        repository.messages(tenant.id),
      ]);
      if (g != _generation) return;
      cost = result[0] as CostBreakdown;
      final page = result[1] as MessagePage;
      history = page.items;
      nextCursor = page.nextCursor;
    } on SmsFailure catch (e) {
      if (g == _generation) error = e.message;
    } catch (_) {
      if (g == _generation) error = 'Something went wrong. Please retry.';
    } finally {
      if (g == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> send(String to, String body) async {
    if (sending || retryAfterSeconds > 0) return false;
    sending = true;
    error = null;
    receipt = null;
    notifyListeners();
    final g = _generation;
    try {
      final value = await repository.send(
        tenant.id,
        SendRequest(to: to.trim(), body: body.trim()),
      );
      if (g != _generation) return false;
      receipt = value;
      await refresh();
      return true;
    } on RateLimitFailure catch (e) {
      if (g == _generation) {
        _rateLimitedUntil = DateTime.now().add(e.retryAfter);
        error = 'Try again in ${e.retryAfter.inSeconds} seconds.';
        _rateLimitTimer?.cancel();
        _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (retryAfterSeconds == 0) {
            timer.cancel();
            _rateLimitedUntil = null;
            error = null;
          }
          notifyListeners();
        });
      }
    } on SmsFailure catch (e) {
      if (g == _generation) error = e.message;
    } catch (_) {
      if (g == _generation) {
        error = 'The request did not complete. Please retry.';
      }
    } finally {
      if (g == _generation) {
        sending = false;
        notifyListeners();
      }
    }
    return false;
  }

  Future<void> loadMore() async {
    if (loadingMore || nextCursor == null) return;
    loadingMore = true;
    notifyListeners();
    final g = _generation;
    try {
      final page = await repository.messages(tenant.id, cursor: nextCursor);
      if (g != _generation) return;
      history = [...history, ...page.items];
      nextCursor = page.nextCursor;
    } on SmsFailure catch (e) {
      if (g == _generation) error = e.message;
    } finally {
      if (g == _generation) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _rateLimitTimer?.cancel();
    super.dispose();
  }
}
