import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';
import 'package:services_rj_example/demos/network/api_playground_page.dart';
import 'package:services_rj_example/demos/network/auth_interceptors_page.dart';
import 'package:services_rj_example/demos/network/cache_lab_page.dart';
import 'package:services_rj_example/demos/network/demo_interceptors.dart';
import 'package:services_rj_example/demos/network/network_logic.dart';
import 'package:services_rj_example/demos/network/permission_setup_page.dart';
import 'package:services_rj_example/demos/network/permissions_page.dart';
import 'package:services_rj_example/demos/network_demos.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

import 'network_test_fakes.dart';

Widget app(Widget page) => MaterialApp(home: page);

void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 9000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test replaces HttpClient with a stub that answers 400; the
  // loopback server tests need the real one.
  HttpOverrides.global = null;

  group('uninitialized', () {
    testWidgets('network pages show the feature-off notice', (tester) async {
      for (final page in const <Widget>[
        ApiPlaygroundPage(),
        CacheLabPage(),
        AuthInterceptorsPage(),
        PermissionsPage(),
      ]) {
        await tester.pumpWidget(app(page));
        expect(find.text('Feature off'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('setup generator works without any feature', (tester) async {
      tallView(tester);
      await tester.pumpWidget(app(const PermissionSetupPage()));
      expect(find.text('Feature off'), findsNothing);
      expect(
        find.textContaining('android.permission.CAMERA', findRichText: true),
        findsOneWidget,
      );
    });

    test('the demo list has five entries and a shared event log', () {
      expect(networkDemos, hasLength(5));
      expect(demoNetworkEvents, isNotNull);
    });
  });

  group('permission setup output', () {
    test('includes the chosen permission only', () {
      final manifest = generateSetup(SetupFormat.androidManifest, {
        AppPermission.camera,
      });
      expect(manifest, contains('android.permission.CAMERA'));
      expect(manifest, isNot(contains('RECORD_AUDIO')));

      final plist = generateSetup(SetupFormat.iosInfoPlist, {
        AppPermission.microphone,
      });
      expect(plist, contains('NSMicrophoneUsageDescription'));

      final pod = generateSetup(SetupFormat.iosPodfile, {
        AppPermission.contacts,
      });
      expect(pod, contains('PERMISSION_CONTACTS=1'));

      expect(generateSetup(SetupFormat.markdown, {}), contains('`camera`'));
    });

    testWidgets('chips change the output and copy uses the clipboard', (
      tester,
    ) async {
      tallView(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(app(const PermissionSetupPage()));
      expect(
        find.textContaining('ACCESS_FINE_LOCATION', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilterChip, 'location'));
      await tester.pump();
      expect(
        find.textContaining('ACCESS_FINE_LOCATION', findRichText: true),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(FilterChip, 'contacts'));
      await tester.pump();
      expect(
        find.textContaining('READ_CONTACTS', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.text('Copy'));
      await tester.pump();
      expect(copied, contains('READ_CONTACTS'));
      expect(find.text('Copied to the clipboard'), findsOneWidget);
    });
  });

  group('initialized', () {
    late HttpServer server;
    late DemoEndpoints endpoints;
    late Directory cacheDir;
    final callbackLog = <String>[];
    var counter = 0;
    var unique = 0;

    String id() => '/posts/${1000 + unique++}';

    setUpAll(() async {
      server = await startLocalServer(() => ++counter);
      endpoints = DemoEndpoints.local(server.port);
      SharedPreferences.setMockInitialValues({});
      cacheDir = Directory.systemTemp.createTempSync('network_demos_cache');
      await AppController.initialize(
        features: const AppFeatures(
          sharedPref: true,
          network: true,
          apiCache: true,
          logger: true,
          networkLogs: true,
          permissions: true,
        ),
        apiConfig: ApiConfig(
          baseUrl: 'http://127.0.0.1:${server.port}',
          tokenHeaderKey: 'X-Token',
          onUnauthorized: () async => callbackLog.add('onUnauthorized'),
          onSessionExpired: () async => callbackLog.add('onSessionExpired'),
          onUserBanned: (m) async => callbackLog.add('onUserBanned'),
          onError: (m) => callbackLog.add('onError'),
        ),
        cacheConfig: const CacheConfig(),
        cacheDirectory: cacheDir,
      );
    });

    tearDownAll(() async {
      await ApiCacheManager.instance.flush();
      await server.close(force: true);
      await cacheDir.delete(recursive: true);
    });

    test(
      'requests carry no token header until an interceptor adds it',
      () async {
        await AuthTokenService.instance.saveToken('tok-123');
        final dio = DioService.instance.dio;

        final before = await dio.get('/headers');
        expect((before.data['headers'] as Map).containsKey('x-token'), isFalse);

        expect(ensureDemoInterceptors(), isTrue);
        expect(
          ensureDemoInterceptors(),
          isTrue,
          reason: 'second call is a no-op',
        );

        final after = await sendDemoRequest(
          ApiRequest(
            endpoint: endpoints.echoHeaders,
            method: ApiMethod.get,
            cachePolicy: CachePolicy.networkOnly,
          ),
        );
        expect(after.response!.data['headers']['x-token'], 'tok-123');

        await AuthTokenService.instance.clearToken();
        expect(AuthTokenService.instance.hasToken, isFalse);
      },
    );

    test('interceptor registers once and counts requests', () async {
      final before = DemoLogInterceptor.requestCount;
      demoNetworkEvents.clear();
      await sendDemoRequest(
        const ApiRequest(
          endpoint: '/posts/1',
          method: ApiMethod.get,
          cachePolicy: CachePolicy.networkOnly,
        ),
      );
      expect(DemoLogInterceptor.requestCount, before + 1);
      expect(
        demoNetworkEvents.lines.where((l) => l.contains('->')),
        hasLength(1),
      );
    });

    group('cache policies', () {
      test('networkOnly never stores', () async {
        final e = id();
        final first = await runPolicy(
          endpoint: e,
          policy: CachePolicy.networkOnly,
          cacheKey: 'k$e',
        );
        expect(first.outcome.source, 'network');
        expect(first.networkCalls, 1);
        final cacheOnly = await runPolicy(
          endpoint: e,
          policy: CachePolicy.cacheOnly,
          cacheKey: 'k$e',
        );
        expect(cacheOnly.outcome.ok, isFalse);
      });

      test('cacheFirst serves a fresh copy without the network', () async {
        final e = id();
        await primeCache(endpoint: e, cacheKey: 'k$e');
        final run = await runPolicy(
          endpoint: e,
          policy: CachePolicy.cacheFirst,
          cacheKey: 'k$e',
        );
        expect(run.outcome.source, 'cache');
        expect(run.networkCalls, 0);
        expect(run.outcome.response!.cachedAt, isNotNull);

        final forced = await runPolicy(
          endpoint: e,
          policy: CachePolicy.cacheFirst,
          cacheKey: 'k$e',
          forceRefresh: true,
        );
        expect(forced.outcome.source, 'network');
        expect(forced.networkCalls, 1);
      });

      test('networkFirst always hits the network', () async {
        final e = id();
        await primeCache(endpoint: e);
        final run = await runPolicy(
          endpoint: e,
          policy: CachePolicy.networkFirst,
        );
        expect(run.outcome.source, 'network');
        expect(run.networkCalls, 1);
      });

      test('cacheOnly reads what was primed', () async {
        final e = id();
        await primeCache(endpoint: e);
        final run = await runPolicy(endpoint: e, policy: CachePolicy.cacheOnly);
        expect(run.outcome.source, 'cache');
        expect(run.networkCalls, 0);
      });

      test('staleWhileRevalidate returns stale data and revalidates', () async {
        final e = id();
        const ttl = Duration(milliseconds: 250);
        await primeCache(endpoint: e, ttl: ttl);
        await Future<void>.delayed(const Duration(milliseconds: 350));
        final revalidated = Completer<ApiResponse<dynamic>>();
        final run = await runPolicy(
          endpoint: e,
          policy: CachePolicy.staleWhileRevalidate,
          ttl: ttl,
          onRevalidated: revalidated.complete,
        );
        expect(run.outcome.source, 'stale cache');
        expect(run.outcome.response!.isStale, isTrue);
        final fresh = await revalidated.future.timeout(
          const Duration(seconds: 3),
        );
        expect(fresh.isFromCache, isFalse);
      });
    });

    test('POST with invalidateCache removes cached GETs', () async {
      final result = await runInvalidateDemo(
        endpoints: const ['/posts/1', '/posts/2'],
        postEndpoint: '/posts',
        prefix: '/posts',
      );
      expect(result.cachedBefore.values, everyElement(isTrue));
      expect(result.cachedAfter.values, everyElement(isFalse));
      expect(result.post.response!.statusCode, 201);
    });

    test('watch emits the cached copy first, then fresh data', () async {
      final e = id();
      const ttl = Duration(milliseconds: 200);
      final request = labRequest(endpoint: e, ttl: ttl);
      await primeCache(endpoint: e, ttl: ttl);
      expect(ApiClient.instance.peek(request), isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final events = await ApiClient.instance.watch(request).toList();
      expect(events.first.isFromCache, isTrue);
      expect(events.last.isFromCache, isFalse);
    });

    test('ApiException getters for 404, 401, 422 and 500', () async {
      Future<RequestOutcome> status(int code) => sendDemoRequest(
        ApiRequest(
          endpoint: endpoints.statusUrl(code),
          method: ApiMethod.get,
          cachePolicy: CachePolicy.networkOnly,
        ),
      );
      expect((await status(404)).error!.isNotFound, isTrue);
      expect((await status(401)).error!.isUnauthorized, isTrue);
      expect((await status(422)).error!.isValidationError, isTrue);
      expect((await status(500)).error!.isServerError, isTrue);
      final unreachable = await sendDemoRequest(
        ApiRequest(
          endpoint: endpoints.invalidHost,
          method: ApiMethod.get,
          cachePolicy: CachePolicy.networkOnly,
        ),
      );
      expect(unreachable.ok, isFalse);
      expect(unreachable.error!.message, 'No internet connection');
    });

    test('the callback bridge forwards status codes', () async {
      callbackLog.clear();
      for (final code in [401, 419, 403, 500]) {
        await sendDemoRequest(
          ApiRequest(
            endpoint: endpoints.statusUrl(code),
            method: ApiMethod.get,
            cachePolicy: CachePolicy.networkOnly,
          ),
        );
      }
      expect(callbackLog, [
        'onUnauthorized',
        'onSessionExpired',
        'onUserBanned',
        'onError',
      ]);
    });

    test('a request can be cancelled', () async {
      final started = startCancellable(endpoints.slow);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      started.cancel.cancel('test');
      final outcome = await started.outcome;
      expect(outcome.ok, isFalse);
      expect(outcome.error!.message, 'Request cancelled');
    });

    test('a short receive timeout fails and is restored', () async {
      final options = DioService.instance.dio.options;
      final before = options.receiveTimeout;
      final outcome = await runTimeoutDemo(
        endpoints.slow,
        const Duration(milliseconds: 300),
      );
      expect(outcome.error!.message, 'Connection timed out');
      expect(options.receiveTimeout, before);
    });

    test('upload reports progress, download saves the file', () async {
      final progress = <UploadProgress>[];
      final file = await createDemoUploadFile(bytes: 40 * 1024);
      final up = await runUpload(
        url: endpoints.upload,
        files: [file],
        onProgress: progress.add,
      );
      expect(up.ok, isTrue);
      expect(progress, isNotEmpty);
      expect(progress.last.percentage, closeTo(100, 0.001));
      expect(up.response!.data['parts'], greaterThan(0));

      final received = <DownloadProgress>[];
      final down = await runDownload(
        url: endpoints.download,
        onProgress: received.add,
      );
      expect(down.ok, isTrue);
      expect(File(demoDownloadPath()).lengthSync(), 20000);
      expect(received.last.percentage, closeTo(100, 0.001));
      expect(progressFraction(5, -1), isNull);
      expect(progressFraction(5, 10), 0.5);
    });

    test('parsers for query, headers and body', () {
      expect(parseQuery('a=1&b=two'), {'a': '1', 'b': 'two'});
      expect(parseQuery(''), isNull);
      expect(parseHeaders('X-A: 1\nbad\nX-B: two'), {'X-A': '1', 'X-B': 'two'});
      expect(parseBody('{"a": 1}'), {'a': 1});
      expect(parseBody('plain'), 'plain');
      expect(parseBody('  '), isNull);
    });

    test('AuthTokenService.logout clears the cache', () async {
      await primeCache(endpoint: id());
      expect(ApiCacheManager.instance.stats.memoryEntries, greaterThan(0));
      await AuthTokenService.instance.logout();
      expect(ApiCacheManager.instance.stats.memoryEntries, 0);
    });

    testWidgets('API playground sends a request and shows the response', (
      tester,
    ) async {
      tallView(tester);
      await tester.pumpWidget(app(ApiPlaygroundPage(endpoints: endpoints)));
      expect(find.text('Feature off'), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text('Send'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      expect(find.textContaining('ApiResponse in'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('404 not found'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      expect(find.textContaining('ApiException in'), findsOneWidget);
    });

    testWidgets('cache lab runs policies and lists the results', (
      tester,
    ) async {
      tallView(tester);
      await tester.pumpWidget(app(const CacheLabPage()));
      expect(find.text('Policy comparison'), findsOneWidget);
      expect(find.text('CacheConfig'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Prime cache'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.tap(find.text('Run all five'));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });
      await tester.pump();
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('cacheOnly'), findsOneWidget);
    });

    testWidgets('auth page shows the echoed headers', (tester) async {
      tallView(tester);
      await tester.pumpWidget(app(AuthInterceptorsPage(endpoints: endpoints)));
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'saveToken'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.tap(find.text('Send to echo endpoint'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      expect(find.text('Headers the server received'), findsOneWidget);
      expect(find.text('demo-token-4f2a9c'), findsWidgets);
    });

    group('permissions page', () {
      late FakeBackend backend;

      // The manager's request queue is a Future created when the backend is
      // set. Created in setUp it would live outside the test's fake-async
      // zone and never complete, so each test installs the backend itself.
      void install() {
        backend = FakeBackend();
        AppPermissionManager.instance
          ..debugSetBackend(backend)
          ..enabled = true;
      }

      testWidgets('lists all 21 tags with live status', (tester) async {
        install();
        tallView(tester);
        await tester.pumpWidget(app(const PermissionsPage()));
        await tester.pumpAndSettle();
        expect(AppPermission.values, hasLength(21));
        final tiles = find.byType(ExpansionTile);
        expect(tiles, findsNWidgets(21));
        for (final p in AppPermission.values) {
          expect(
            find.descendant(of: tiles, matching: find.text(p.name)),
            findsOneWidget,
            reason: p.name,
          );
        }
        expect(find.text('denied'), findsWidgets);
      });

      testWidgets('search filters and request updates the chip', (
        tester,
      ) async {
        install();
        tallView(tester);
        await tester.pumpWidget(app(const PermissionsPage()));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'camera');
        await tester.pumpAndSettle();
        expect(find.byType(ExpansionTile), findsOneWidget);

        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'request'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(ExpansionTile),
            matching: find.text('granted'),
          ),
          findsOneWidget,
        );
        expect(backend.requested, isNotEmpty);
      });

      testWidgets('re-checks when the app resumes', (tester) async {
        install();
        tallView(tester);
        await tester.pumpWidget(app(const PermissionsPage()));
        await tester.pumpAndSettle();
        grantCamera(backend);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(find.text('granted'), findsWidgets);
      });
    });
  });
}
