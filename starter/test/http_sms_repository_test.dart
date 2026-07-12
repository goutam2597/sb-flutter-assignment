import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starter/data/http_sms_repository.dart';
import 'package:starter/domain/models.dart';

class _Tokens implements AccessTokenProvider {
  @override
  Future<String?> accessToken() async => 'short-lived-test-token';
}

void main() {
  test('rejects a cleartext API base URL', () {
    expect(
      () => HttpSmsRepository(
        baseUri: Uri.parse('http://api.example.test'),
        tokens: _Tokens(),
      ),
      throwsArgumentError,
    );
  });

  test(
    'send includes auth and tenant headers and parses authoritative money',
    () async {
      late http.Request captured;
      final repository = HttpSmsRepository(
        baseUri: Uri.parse('https://api.example.test'),
        tokens: _Tokens(),
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'messageId': 'SM1',
              'provider': 'TWILIO',
              'status': 'ACCEPTED',
              'segmentCount': 3,
              'cost': '0.0237',
              'currency': 'EUR',
            }),
            202,
          );
        }),
      );

      final receipt = await repository.send(
        'tenant-a',
        const SendRequest(
          to: '+4915112345678',
          body: 'Hello',
          referenceId: 'ref-1',
        ),
      );

      expect(
        captured.headers['authorization'],
        'Bearer short-lived-test-token',
      );
      expect(captured.headers['x-tenant-id'], 'tenant-a');
      expect(receipt.segmentCount, 3);
      expect(receipt.cost, Money.parse('0.0237', 'EUR'));
      expect(receipt.status, DeliveryStatus.accepted);
    },
  );

  test('429 maps Retry-After seconds into typed failure', () async {
    final repository = HttpSmsRepository(
      baseUri: Uri.parse('https://api.example.test'),
      tokens: _Tokens(),
      client: MockClient(
        (_) async => http.Response('', 429, headers: {'retry-after': '17'}),
      ),
    );

    await expectLater(
      repository.send(
        'tenant-a',
        const SendRequest(to: '+4915112345678', body: 'Hello'),
      ),
      throwsA(
        isA<RateLimitFailure>().having(
          (failure) => failure.retryAfter,
          'retryAfter',
          const Duration(seconds: 17),
        ),
      ),
    );
  });

  test('502 maps to provider unavailable and never reports success', () async {
    final repository = HttpSmsRepository(
      baseUri: Uri.parse('https://api.example.test'),
      tokens: _Tokens(),
      client: MockClient((_) async => http.Response('', 502)),
    );
    await expectLater(
      repository.send(
        'tenant-a',
        const SendRequest(to: '+4915112345678', body: 'Hello'),
      ),
      throwsA(isA<ProviderFailure>()),
    );
  });

  test('slow request terminates as a typed timeout', () async {
    final repository = HttpSmsRepository(
      baseUri: Uri.parse('https://api.example.test'),
      tokens: _Tokens(),
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      repository.messages('tenant-a'),
      throwsA(isA<TimeoutFailure>()),
    );
  });

  test('history forwards the opaque cursor without decoding it', () async {
    late Uri captured;
    final repository = HttpSmsRepository(
      baseUri: Uri.parse('https://api.example.test'),
      tokens: _Tokens(),
      client: MockClient((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode({'items': <Object?>[], 'nextCursor': null}),
          200,
        );
      }),
    );

    await repository.messages(
      'tenant-a',
      cursor: 'eyJvZmZzZXQiOjUwfQ',
      limit: 50,
    );
    expect(captured.queryParameters['cursor'], 'eyJvZmZzZXQiOjUwfQ');
  });

  test('malformed success response becomes parsing failure', () async {
    final repository = HttpSmsRepository(
      baseUri: Uri.parse('https://api.example.test'),
      tokens: _Tokens(),
      client: MockClient((_) async => http.Response('{}', 202)),
    );
    await expectLater(
      repository.send(
        'tenant-a',
        const SendRequest(to: '+4915112345678', body: 'Hello'),
      ),
      throwsA(isA<ParsingFailure>()),
    );
  });
}
