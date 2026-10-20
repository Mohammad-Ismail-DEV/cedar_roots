import 'dart:convert';

import 'package:cedar_roots/core/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient clientFor(
  Future<http.Response> Function(http.Request) handler, {
  String? token = 'tok',
  String baseUrl = 'https://api.example.com',
  void Function()? onUnauthorized,
}) => ApiClient(
  baseUrl: baseUrl,
  tokenReader: () => token,
  onUnauthorized: onUnauthorized,
  client: MockClient(handler),
);

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('sends the bearer token and drops null query values', () async {
    late http.Request seen;
    final api = clientFor((request) async {
      seen = request;
      return json({'ok': true});
    });

    final data = await api.get(
      '/posts',
      query: {'user_id': 4, 'skipped': null},
    );

    expect(data, {'ok': true});
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(seen.url.toString(), 'https://api.example.com/posts?user_id=4');
  });

  test('sends no Authorization header when signed out', () async {
    late http.Request seen;
    final api = clientFor((request) async {
      seen = request;
      return json([]);
    }, token: null);

    await api.get('/posts');
    expect(seen.headers.containsKey('Authorization'), isFalse);
  });

  test('adds the ngrok header only for ngrok hosts', () async {
    final seen = <String, bool>{};
    Future<http.Response> record(http.Request r) async {
      seen[r.url.host] = r.headers.containsKey('ngrok-skip-browser-warning');
      return json({});
    }

    await clientFor(record, baseUrl: 'https://abc.ngrok-free.app').get('/x');
    await clientFor(record, baseUrl: 'https://api.example.com').get('/x');

    expect(seen['abc.ngrok-free.app'], isTrue);
    expect(seen['api.example.com'], isFalse);
  });

  test('encodes a JSON body, including on DELETE', () async {
    late http.Request seen;
    final api = clientFor((request) async {
      seen = request;
      return json({});
    });

    await api.delete('/organization_members', body: {'user_id': 1});

    expect(seen.method, 'DELETE');
    expect(jsonDecode(seen.body), {'user_id': 1});
    expect(seen.headers['Content-Type'], contains('application/json'));
  });

  test(
    'turns error responses into ApiException with the server message',
    () async {
      final api = clientFor(
        (_) async => json({'error': 'Nope', 'message': 'Nope'}, 403),
      );

      await expectLater(
        api.get('/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Nope'),
        ),
      );
    },
  );

  test('falls back to a generic message for non-JSON failures', () async {
    final api = clientFor((_) async => http.Response('<html>', 502));

    await expectLater(
      api.get('/x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('502'),
        ),
      ),
    );
  });

  test('a 401 while signed in triggers onUnauthorized', () async {
    var signedOut = 0;
    final api = clientFor(
      (_) async => json({'error': 'expired'}, 401),
      onUnauthorized: () => signedOut++,
    );

    await expectLater(api.get('/x'), throwsA(isA<ApiException>()));
    expect(signedOut, 1);
  });

  test(
    'a 401 with no token (a failed login) does not sign anyone out',
    () async {
      var signedOut = 0;
      final api = clientFor(
        (_) async => json({'error': 'Invalid email or password'}, 401),
        token: null,
        onUnauthorized: () => signedOut++,
      );

      await expectLater(
        api.post('/auth/login', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isUnauthorized,
            'isUnauthorized',
            isTrue,
          ),
        ),
      );
      expect(signedOut, 0);
    },
  );

  test('network failures become status 0', () async {
    final api = clientFor((_) async => throw http.ClientException('down'));

    await expectLater(
      api.get('/x'),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', isTrue),
      ),
    );
  });
}
