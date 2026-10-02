import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAdapter implements HttpClientAdapter {
  int calls = 0;
  dynamic body = {'value': 1};
  int status = 200;
  bool offline = false;
  Duration delay = Duration.zero;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    await Future<void>.delayed(delay);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Uint8List testKey() => Uint8List.fromList(List.generate(32, (i) => i));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FakeAdapter http;
  final api = ApiClient.instance;
  final cache = ApiCacheManager.instance;

  var n = 0;
  String uniq() => '/items/${n++}';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('services_rj_cache');
    await AppController.initialize(
      features: const AppFeatures(
        network: true,
        apiCache: true,
        encryption: true,
      ),
      apiConfig: const ApiConfig(baseUrl: 'https://example.test'),
      encryptionKeyProvider: () async => testKey(),
      cacheDirectory: dir,
    );
    http = FakeAdapter();
    DioService.instance.dio.httpClientAdapter = http;
  });

  setUp(() {
    http
      ..calls = 0
      ..body = {'value': 1}
      ..status = 200
      ..offline = false
      ..delay = Duration.zero;
  });

  tearDownAll(() async {
    await cache.flush();
    await dir.delete(recursive: true);
  });

  ApiRequest get(
    String endpoint, {
    CachePolicy? policy,
    Duration? ttl,
    void Function(ApiResponse<dynamic>)? onRevalidated,
  }) => ApiRequest(
    endpoint: endpoint,
    method: ApiMethod.get,
    cachePolicy: policy,
    cacheTtl: ttl,
    onRevalidated: onRevalidated,
  );

  test('controller starts explicitly enabled cache and encryption', () {
    expect(AppController.instance.isReady(AppFeature.apiCache), isTrue);
    expect(AppController.instance.isReady(AppFeature.encryption), isTrue);
    expect(cache.config.defaultPolicy, CachePolicy.staleWhileRevalidate);
  });

  group('stale-while-revalidate', () {
    test('fresh cache answers without network', () async {
      final e = uniq();
      final first = await api.request(get(e));
      expect(first.isFromCache, isFalse);

      final second = await api.request(get(e));
      expect(second.isFromCache, isTrue);
      expect(second.isStale, isFalse);
      expect(second.data, {'value': 1});
      expect(http.calls, 1);
    });

    test(
      'stale cache answers instantly and refreshes in the background',
      () async {
        final e = uniq();
        await api.request(get(e, ttl: Duration.zero));

        http
          ..body = {'value': 2}
          ..delay = const Duration(milliseconds: 50);
        final refreshed = Completer<ApiResponse<dynamic>>();

        final watch = Stopwatch()..start();
        final stale = await api.request(
          get(e, ttl: Duration.zero, onRevalidated: refreshed.complete),
        );
        watch.stop();

        expect(stale.isFromCache, isTrue);
        expect(stale.isStale, isTrue);
        expect(stale.data, {'value': 1});
        expect(
          watch.elapsedMilliseconds,
          lessThan(50),
          reason: 'must not wait for the network',
        );

        final fresh = await refreshed.future;
        expect(fresh.data, {'value': 2});
        await cache.flush();
        // peek, not request: a request would start another background refresh
        // that leaks into the next test.
        expect(api.peek(get(e))!.data, {'value': 2});
      },
    );

    test('onRevalidated is not called when data did not change', () async {
      final e = uniq();
      await api.request(get(e, ttl: Duration.zero));
      var called = false;
      await api.request(
        get(e, ttl: Duration.zero, onRevalidated: (_) => called = true),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(http.calls, 2);
      expect(called, isFalse);
    });
  });

  group('fallbacks', () {
    test('networkFirst serves cache when offline', () async {
      final e = uniq();
      await api.request(get(e, policy: CachePolicy.networkFirst));
      http.offline = true;
      final res = await api.request(get(e, policy: CachePolicy.networkFirst));
      expect(res.isFromCache, isTrue);
      expect(res.data, {'value': 1});
    });

    test('networkFirst serves cache on 5xx', () async {
      final e = uniq();
      await api.request(get(e, policy: CachePolicy.networkFirst));
      http.status = 503;
      final res = await api.request(get(e, policy: CachePolicy.networkFirst));
      expect(res.isFromCache, isTrue);
    });

    test('4xx is not hidden behind cached data', () async {
      final e = uniq();
      await api.request(get(e, policy: CachePolicy.networkFirst));
      http
        ..status = 404
        ..body = {'message': 'gone'};
      await expectLater(
        api.request(get(e, policy: CachePolicy.networkFirst)),
        throwsA(
          isA<ApiException>()
              .having((x) => x.statusCode, 'status', 404)
              .having((x) => x.message, 'message', 'gone'),
        ),
      );
    });

    test('offline without cache throws a clear ApiException', () async {
      http.offline = true;
      await expectLater(
        api.request(get(uniq())),
        throwsA(
          isA<ApiException>().having(
            (x) => x.message,
            'message',
            'No internet connection',
          ),
        ),
      );
    });

    test('cacheOnly without data throws', () async {
      await expectLater(
        api.request(get(uniq(), policy: CachePolicy.cacheOnly)),
        throwsA(isA<ApiException>()),
      );
      expect(http.calls, 0);
    });

    test('networkOnly never reads the cache', () async {
      final e = uniq();
      await api.request(get(e));
      final res = await api.request(get(e, policy: CachePolicy.networkOnly));
      expect(res.isFromCache, isFalse);
      expect(http.calls, 2);
    });
  });

  group('behaviour', () {
    test('concurrent identical requests share one network call', () async {
      http.delay = const Duration(milliseconds: 30);
      final e = uniq();
      await Future.wait([
        api.request(get(e)),
        api.request(get(e)),
        api.request(get(e)),
      ]);
      expect(http.calls, 1);
    });

    test('POST is not cached by default and can invalidate GETs', () async {
      await api.request(get('/posts'));
      await api.request(get('/posts', ttl: const Duration(hours: 1)));
      expect(http.calls, 1);

      const post = ApiRequest(
        endpoint: '/posts',
        method: ApiMethod.post,
        body: {'t': 'x'},
        invalidateCache: ['/posts'],
      );
      await api.request(post);
      await api.request(post);
      expect(http.calls, 3);

      await api.request(get('/posts'));
      expect(http.calls, 4, reason: 'GET /posts was invalidated');
    });

    test('query order does not change the key', () {
      const a = ApiRequest(
        endpoint: '/q',
        method: ApiMethod.get,
        queryParameters: {'a': 1, 'b': 2},
      );
      const b = ApiRequest(
        endpoint: '/q',
        method: ApiMethod.get,
        queryParameters: {'b': 2, 'a': 1},
      );
      expect(cache.keyFor(a), cache.keyFor(b));
    });

    test('scope separates users', () async {
      final e = uniq();
      cache.scope = 'user-a';
      await api.request(get(e));
      cache.scope = 'user-b';
      final res = await api.request(get(e));
      expect(res.isFromCache, isFalse);
      cache.scope = '';
    });

    test('peek returns cached data synchronously', () async {
      final e = uniq();
      expect(api.peek(get(e)), isNull);
      await api.request(get(e));
      expect(api.peek(get(e))!.data, {'value': 1});
    });

    test('watch emits cache first, then fresh data', () async {
      final e = uniq();
      await api.request(get(e, ttl: Duration.zero));
      http.body = {'value': 9};
      final events = await api.watch(get(e, ttl: Duration.zero)).toList();
      expect(events.map((r) => r.isFromCache), [true, false]);
      expect(events.last.data, {'value': 9});
    });

    test('runtime switch-off bypasses the cache', () async {
      final e = uniq();
      await api.request(get(e));
      await AppController.instance.setEnabled(AppFeature.apiCache, false);
      final res = await api.request(get(e));
      expect(res.isFromCache, isFalse);
      await AppController.instance.setEnabled(AppFeature.apiCache, true);
    });
  });

  group('storage and security', () {
    test('files on disk are encrypted and named by hash', () async {
      http.body = {'secret': 'very-private-value'};
      await api.request(get('/secret-endpoint'));
      await cache.flush();

      final files = dir.listSync(recursive: true).whereType<File>().toList();
      expect(files, isNotEmpty);
      for (final f in files) {
        expect(f.path, endsWith('.enc'));
        expect(f.path.contains('secret-endpoint'), isFalse);
        final raw = latin1.decode(f.readAsBytesSync());
        expect(raw.contains('very-private-value'), isFalse);
        expect(raw.contains('secret-endpoint'), isFalse);
      }
    });

    test('data survives a restart and is preloaded into memory', () async {
      final e = uniq();
      http.body = {'kept': true};
      await api.request(get(e, ttl: const Duration(hours: 1)));
      await cache.flush();

      cache.reset();
      await cache.initialize(const CacheConfig(), directoryOverride: dir);

      final instant = api.peek(get(e));
      expect(instant, isNotNull, reason: 'preloaded before the first frame');
      expect(instant!.data, {'kept': true});
      expect(http.calls, 1);
    });

    test('a tampered file is discarded, not trusted', () async {
      final e = uniq();
      await api.request(get(e, ttl: const Duration(hours: 1)));
      await cache.flush();

      final hash = AppEncryption.sha256Hex(
        cache.keyFor(get(e), baseUrl: 'https://example.test'),
      );
      final file = File('${dir.path}/services_rj_api_cache/$hash.enc');
      expect(file.existsSync(), isTrue);
      final bytes = file.readAsBytesSync();
      bytes[bytes.length - 1] ^= 0xFF;
      file.writeAsBytesSync(bytes);

      cache.reset();
      await cache.initialize(
        const CacheConfig(preloadOnStart: false),
        directoryOverride: dir,
      );

      final res = await api.request(get(e));
      expect(res.isFromCache, isFalse);
      expect(http.calls, 2);
    });

    test('disk limit evicts the oldest entries', () async {
      await cache.clear();
      await cache.flush();
      cache.reset();
      await cache.initialize(
        const CacheConfig(maxDiskBytes: 2000),
        directoryOverride: dir,
      );

      http.body = {'pad': 'x' * 300};
      for (var i = 0; i < 20; i++) {
        await api.request(get(uniq()));
      }
      await cache.flush();
      expect(cache.stats.diskBytes, lessThanOrEqualTo(2000));
    });

    test('logout wipes the cache', () async {
      final e = uniq();
      await api.request(get(e));
      await AppController.instance.logout();
      await cache.flush();
      expect(api.peek(get(e)), isNull);
      expect(cache.stats.diskBytes, 0);
    });
  });
}
