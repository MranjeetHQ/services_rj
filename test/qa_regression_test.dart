// One regression test per flaw found in the QA review (docs/qa_report.md).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:services_rj/services_rj.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScriptedAdapter implements HttpClientAdapter {
  int calls = 0;
  Duration delay = Duration.zero;
  int status = 200;
  String body = jsonEncode({'user': 'A'});
  String contentType = Headers.jsonContentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? cancel,
  ) async {
    calls++;
    // Capture the response now, like a real server answering this request.
    final reply = body, code = status, type = contentType;
    final done = Future<void>.delayed(delay);
    if (cancel != null) {
      await Future.any([done, cancel]);
      if (o.cancelToken?.isCancelled ?? false) {
        throw DioException.requestCancelled(
          requestOptions: o,
          reason: 'cancelled',
        );
      }
    } else {
      await done;
    }
    return ResponseBody.fromString(
      reply,
      code,
      headers: {
        Headers.contentTypeHeader: [type],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class SettingsBackend extends PermissionBackend {
  @override
  PermissionPlatform get platform => PermissionPlatform.ios;
  @override
  Future<PermissionStatus> status(Permission p) async =>
      PermissionStatus.permanentlyDenied;
  @override
  Future<bool> openSettings() async => true; // "opened", but the app never leaves
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late ScriptedAdapter http;
  final api = ApiClient.instance;
  final cache = ApiCacheManager.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('services_rj_qa');
    await AppController.initialize(
      features: const AppFeatures(connectivity: false),
      apiConfig: const ApiConfig(baseUrl: 'https://qa.test'),
      cacheDirectory: dir,
    );
    http = ScriptedAdapter();
    DioService.instance.dio.httpClientAdapter = http;
  });

  setUp(() {
    http
      ..calls = 0
      ..delay = Duration.zero
      ..status = 200
      ..body = jsonEncode({'user': 'A'})
      ..contentType = Headers.jsonContentType;
  });

  tearDownAll(() async {
    await cache.flush();
    await dir.delete(recursive: true);
  });

  test(
    'QA-1: a response that lands after logout is not cached or shared',
    () async {
      http.delay = const Duration(milliseconds: 80);
      const req = ApiRequest(endpoint: '/me', method: ApiMethod.get);

      final userA = api.request(req); // in flight for user A
      while (http.calls == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await AppController.instance.logout();

      http.body = jsonEncode({'user': 'B'});
      final userB = api.request(req); // user B must not join A's request

      expect((await userA).data, {'user': 'A'});
      expect((await userB).data, {'user': 'B'});
      expect(http.calls, 2);
      await cache.flush();
      expect(api.peek(req)!.data, {'user': 'B'});
    },
  );

  test(
    'QA-2: cancelling one request does not cancel an identical one',
    () async {
      http.delay = const Duration(milliseconds: 60);
      final token = CancelRequest();
      const endpoint = '/shared';

      final cancelled = api.request(
        ApiRequest(
          endpoint: endpoint,
          method: ApiMethod.get,
          cancelRequest: token,
        ),
      );
      final other = api.request(
        const ApiRequest(endpoint: endpoint, method: ApiMethod.get),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      token.cancel();

      await expectLater(cancelled, throwsA(isA<ApiException>()));
      expect((await other).data, {'user': 'A'});
    },
  );

  test('QA-4: 204 No Content is a success', () async {
    http
      ..status = 204
      ..body = '';
    final res = await api.request(
      const ApiRequest(endpoint: '/items/1', method: ApiMethod.delete),
    );
    expect(res.success, isTrue);
    expect(res.statusCode, 204);
  });

  test('QA-4: a plain-text error body gives a clean ApiException', () async {
    http
      ..status = 500
      ..body = 'Internal Server Error'
      ..contentType = 'text/plain';
    await expectLater(
      api.request(const ApiRequest(endpoint: '/boom', method: ApiMethod.post)),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 500)),
    );
  });

  test(
    'QA-5: settings that never take the app to background do not block the queue',
    () async {
      final m = AppPermissionManager.instance
        ..debugSetBackend(SettingsBackend())
        ..settingsLeaveTimeout = const Duration(milliseconds: 100);

      final watch = Stopwatch()..start();
      final status = await m.ensure(
        AppPermission.camera,
        prompts: PermissionPrompts(onOpenSettings: (_) async => true),
      );
      expect(status, AppPermissionStatus.permanentlyDenied);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));

      // The queue is free again.
      expect(
        await m.request(AppPermission.sms),
        AppPermissionStatus.notApplicable,
      );
    },
  );

  group('encryption key handling', () {
    final crypto = AppEncryption.instance;

    test(
      'QA-6: an unreadable stored key is replaced instead of crashing start-up',
      () async {
        crypto.reset();
        FlutterSecureStorage.setMockInitialValues({
          'services_rj_data_key_v1': '!!not-base64!!',
        });
        await crypto.initialize();
        expect(crypto.isInitialized, isTrue);
        expect(crypto.decrypt(crypto.encrypt('ok')), 'ok');
      },
    );

    test('QA-7: concurrent initialize creates exactly one key', () async {
      crypto.reset();
      FlutterSecureStorage.setMockInitialValues({});
      await Future.wait([
        crypto.initialize(),
        crypto.initialize(),
        crypto.initialize(),
      ]);
      final c = crypto.encrypt('same key');
      final stored = await const FlutterSecureStorage().read(
        key: 'services_rj_data_key_v1',
      );
      crypto.reset();
      await crypto.initialize(keyProvider: () async => base64Decode(stored!));
      expect(crypto.decrypt(c), 'same key');
    });

    test('QA-8: wipeAllData keeps using the custom key provider', () async {
      crypto.reset();
      var calls = 0;
      final key = Uint8List.fromList(List.filled(32, 7));
      await crypto.initialize(
        keyProvider: () async {
          calls++;
          return key;
        },
      );
      await AppController.instance.wipeAllData(destroyEncryptionKey: true);
      expect(calls, 2);
      expect(crypto.isInitialized, isTrue);
    });
  });

  test(
    'QA-9: enabling the cache at runtime uses the CacheConfig from initialize',
    () async {
      AppController.instance.resetForTest();
      final dir2 = await Directory.systemTemp.createTemp('services_rj_qa9');
      await AppController.initialize(
        features: const AppFeatures(
          apiCache: false,
          connectivity: false,
          encryption: false,
        ),
        apiConfig: const ApiConfig(baseUrl: 'https://qa.test'),
        cacheConfig: const CacheConfig(defaultTtl: Duration(hours: 6)),
        cacheDirectory: dir2,
      );
      expect(AppController.instance.isReady(AppFeature.apiCache), isFalse);

      await AppController.instance.setEnabled(AppFeature.apiCache, true);
      expect(AppController.instance.isReady(AppFeature.apiCache), isTrue);
      expect(cache.config.defaultTtl, const Duration(hours: 6));
      await cache.flush();
      await dir2.delete(recursive: true);
    },
  );
}
