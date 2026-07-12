import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models.dart';
import '../domain/sms_repository.dart';

abstract interface class AccessTokenProvider {
  Future<String?> accessToken();
}

class HttpSmsRepository implements SmsRepository {
  HttpSmsRepository({
    required this.baseUri,
    required this.tokens,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.historyCurrency = 'EUR',
  }) : _client = client ?? http.Client() {
    if (baseUri.scheme != 'https') {
      throw ArgumentError('The SMS API base URL must use HTTPS');
    }
  }

  final Uri baseUri;
  final AccessTokenProvider tokens;
  final Duration timeout;
  final String historyCurrency;
  final http.Client _client;

  static Uri? configuredBaseUri() {
    const value = String.fromEnvironment('SMS_API_BASE_URL');
    return value.isEmpty ? null : Uri.tryParse(value);
  }

  @override
  Future<SendReceipt> send(String tenantId, SendRequest request) async {
    final response = await _perform(
      tenantId,
      (headers) => _client.post(
        _uri('/api/v1/sms/send'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': request.to,
          'body': request.body,
          if (request.referenceId != null) 'referenceId': request.referenceId,
        }),
      ),
    );
    _requireStatus(response, 202);
    final json = _object(response.body);
    final currency = _string(json, 'currency');
    return SendReceipt(
      messageId: _string(json, 'messageId'),
      provider: _string(json, 'provider'),
      status: _status(_string(json, 'status')),
      segmentCount: _integer(json, 'segmentCount'),
      cost: Money.parse(_string(json, 'cost'), currency),
      currency: currency,
    );
  }

  @override
  Future<CostBreakdown> costs(String tenantId) async {
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month);
    final response = await _perform(
      tenantId,
      (headers) => _client.get(
        _uri('/api/v1/sms/cost/breakdown', {
          'from': from.toIso8601String(),
          'to': now.toIso8601String(),
        }),
        headers: headers,
      ),
    );
    _requireStatus(response, 200);
    final json = _object(response.body);
    final currency = _string(json, 'currency');
    final rows = _list(json, 'rows')
        .map((value) {
          final row = _map(value);
          return CostRow(
            _string(row, 'provider'),
            Money.parse(_string(row, 'totalCost'), currency),
            _integer(row, 'messageCount'),
          );
        })
        .toList(growable: false);
    return CostBreakdown(
      currency,
      Money.parse(_string(json, 'totalCost'), currency),
      rows,
    );
  }

  @override
  Future<MessagePage> messages(
    String tenantId, {
    String? cursor,
    int limit = 50,
  }) async {
    final query = {'limit': '$limit'};
    if (cursor != null) query['cursor'] = cursor;
    final response = await _perform(
      tenantId,
      (headers) =>
          _client.get(_uri('/api/v1/sms/messages', query), headers: headers),
    );
    _requireStatus(response, 200);
    final json = _object(response.body);
    final items = _list(json, 'items')
        .map((value) {
          final item = _map(value);
          return MessageRecord(
            messageId: _string(item, 'messageId'),
            recipient: _string(item, 'recipient'),
            status: _status(_string(item, 'status')),
            segmentCount: _integer(item, 'segmentCount'),
            cost: Money.parse(_string(item, 'cost'), historyCurrency),
            sentAt: DateTime.parse(_string(item, 'sentAt')).toUtc(),
          );
        })
        .toList(growable: false);
    final next = json['nextCursor'];
    if (next != null && next is! String) throw const ParsingFailure();
    return MessagePage(items, next as String?);
  }

  Future<http.Response> _perform(
    String tenantId,
    Future<http.Response> Function(Map<String, String>) request,
  ) async {
    final token = await tokens.accessToken();
    if (token == null || token.isEmpty) throw const UnauthorizedFailure();
    try {
      return await request({
        'Authorization': 'Bearer $token',
        'X-Tenant-Id': tenantId,
        'Accept': 'application/json',
      }).timeout(timeout);
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException {
      throw const OfflineFailure();
    }
  }

  void _requireStatus(http.Response response, int expected) {
    if (response.statusCode == expected) return;
    switch (response.statusCode) {
      case 400:
        throw ValidationFailure(_serverMessage(response));
      case 401:
        throw const UnauthorizedFailure();
      case 403:
        throw const ForbiddenFailure();
      case 429:
        final seconds = int.tryParse(response.headers['retry-after'] ?? '');
        throw RateLimitFailure(Duration(seconds: seconds ?? 1));
      case 502:
        throw const ProviderFailure();
      default:
        throw const SmsFailureUnknown();
    }
  }

  String _serverMessage(http.Response response) {
    try {
      return _string(_object(response.body), 'message');
    } catch (_) {
      return 'The request was not valid.';
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) => baseUri.replace(
    path: '${baseUri.path.replaceAll(RegExp(r'/$'), '')}$path',
    queryParameters: query,
  );

  Map<String, Object?> _object(String body) {
    try {
      return _map(jsonDecode(body));
    } catch (_) {
      throw const ParsingFailure();
    }
  }

  Map<String, Object?> _map(Object? value) {
    if (value is! Map<String, dynamic>) throw const ParsingFailure();
    return value.cast<String, Object?>();
  }

  List<Object?> _list(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List) throw const ParsingFailure();
    return value.cast<Object?>();
  }

  String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) throw const ParsingFailure();
    return value;
  }

  int _integer(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) throw const ParsingFailure();
    return value;
  }

  DeliveryStatus _status(String value) => switch (value) {
    'ACCEPTED' => DeliveryStatus.accepted,
    'SENT' => DeliveryStatus.sent,
    'DELIVERED' => DeliveryStatus.delivered,
    'FAILED' => DeliveryStatus.failed,
    _ => throw const ParsingFailure(),
  };
}
