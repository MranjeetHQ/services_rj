import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'demo_interceptors.dart';
import 'network_common.dart';
import 'network_logic.dart';

/// Token storage, header injection, interceptors and the global callbacks.
class AuthInterceptorsPage extends StatelessWidget {
  /// Creates the page. [endpoints] is replaced by a local server in tests.
  const AuthInterceptorsPage({
    super.key,
    this.endpoints = const DemoEndpoints(),
  });

  /// Absolute URLs for the echo and status calls.
  final DemoEndpoints endpoints;

  @override
  Widget build(BuildContext context) => FeatureGate(
    title: 'Auth and interceptors',
    features: const [AppFeature.network],
    builder: (_) => _AuthBody(endpoints: endpoints),
  );
}

class _AuthBody extends StatefulWidget {
  const _AuthBody({required this.endpoints});

  final DemoEndpoints endpoints;

  @override
  State<_AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<_AuthBody> {
  final _token = TextEditingController(text: 'demo-token-4f2a9c');
  String _note = '';
  RequestOutcome? _echo;
  String _rawResult = '';

  AppController get _app => AppController.instance;

  bool get _hasStorage => _app.isReady(AppFeature.sharedPref);

  @override
  void initState() {
    super.initState();
    ensureDemoInterceptors();
    ensurePackageAuthInterceptor();
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await AuthTokenService.instance.saveToken(_token.text.trim());
    if (mounted) setState(() => _note = 'saveToken returned $ok');
  }

  Future<void> _clear() async {
    await AuthTokenService.instance.clearToken();
    if (mounted) setState(() => _note = 'clearToken done');
  }

  Future<void> _logout() async {
    final cache = ApiCacheManager.instance;
    final before = cache.stats.memoryEntries;
    await AuthTokenService.instance.logout();
    if (!mounted) return;
    setState(() {
      _note =
          'logout done. Cache entries in memory: $before -> '
          '${cache.stats.memoryEntries} '
          '(clearOnLogout is ${cache.config.clearOnLogout}).';
    });
  }

  Future<void> _sendEcho() async {
    final outcome = await sendDemoRequest(
      ApiRequest(
        endpoint: widget.endpoints.echoHeaders,
        method: ApiMethod.get,
        cachePolicy: CachePolicy.networkOnly,
      ),
    );
    if (mounted) setState(() => _echo = outcome);
  }

  Future<void> _trigger(int code) async {
    demoNetworkEvents.add('[demo] requesting status $code');
    await sendDemoRequest(
      ApiRequest(
        endpoint: widget.endpoints.statusUrl(code),
        method: ApiMethod.get,
        cachePolicy: CachePolicy.networkOnly,
      ),
    );
  }

  Future<void> _rawDio() async {
    final dio = DioService.instance.dio;
    try {
      final response = await dio.get('/todos/1');
      if (!mounted) return;
      setState(
        () => _rawResult =
            'dio.get -> ${response.statusCode}\n${previewData(response.data, maxChars: 300)}',
      );
    } catch (e) {
      if (mounted) setState(() => _rawResult = 'dio.get threw: $e');
    }
  }

  List<(String, String)> _echoRows(RequestOutcome o) {
    if (!o.ok) return [('error', '${o.error}')];
    final data = o.response!.data;
    final headers = data is Map ? data['headers'] : null;
    if (headers is! Map) return [('data', previewData(data))];
    final key = _app.apiConfig?.tokenHeaderKey;
    return [
      if (key != null)
        (
          'header "$key"',
          '${headers.entries.where((e) => e.key.toString().toLowerCase() == key.toLowerCase()).map((e) => e.value).firstOrNull ?? '(not sent)'}',
        ),
      for (final e in headers.entries) ('${e.key}', '${e.value}'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = _app.apiConfig;
    final dio = DioService.instance.dio;
    final token = _hasStorage ? AuthTokenService.instance.token : null;
    return DemoPage(
      title: 'Auth and interceptors',
      intro:
          'The auth token lives in AuthTokenService. Interceptors see every '
          'request that goes through DioService.',
      children: [
        DemoSection(
          title: 'AuthTokenService',
          subtitle:
              'Persists the token with SharedPrefManager (so it needs the '
              'sharedPref feature).',
          code:
              "await AuthTokenService.instance.saveToken(token);\nAuthTokenService.instance.hasToken; // true\nawait AuthTokenService.instance.logout();",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasStorage)
                const Text(
                  'sharedPref is off, so tokens cannot be stored. Enable it on '
                  'the AppController page.',
                )
              else ...[
                KeyValueTable([
                  ('token', token ?? 'null'),
                  ('hasToken', '${AuthTokenService.instance.hasToken}'),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _token,
                  decoration: const InputDecoration(
                    labelText: 'Token',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _save,
                      child: const Text('saveToken'),
                    ),
                    OutlinedButton(
                      onPressed: _clear,
                      child: const Text('clearToken'),
                    ),
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('logout'),
                    ),
                  ],
                ),
                if (_note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_note),
                  ),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Token header injection',
          subtitle:
              'ApiConfig.tokenHeaderKey names the header that should carry '
              'the token (here: "${config?.tokenHeaderKey}"). The demo '
              'registers an interceptor that applies it. Send a request to an '
              'echo endpoint to see what the server received.',
          code:
              "class TokenHeaderInterceptor extends ApiInterceptor {\n  @override\n  Future<void> onRequest(options) async {\n    final key = AppController.instance.apiConfig?.tokenHeaderKey;\n    final token = AuthTokenService.instance.token;\n    if (key != null && token != null) options.headers[key] = token;\n  }\n}\n\nDioService.instance.addInterceptor(TokenHeaderInterceptor());",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Demo TokenHeaderInterceptor'),
                subtitle: const Text(
                  'Sends the raw token under ApiConfig.tokenHeaderKey.',
                ),
                value: TokenHeaderInterceptor.enabled,
                onChanged: (v) =>
                    setState(() => TokenHeaderInterceptor.enabled = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Package AuthInterceptor'),
                subtitle: const Text(
                  'Added to DioService.instance.dio.interceptors. Sends '
                  '"Authorization: Bearer <token>" and calls onRefreshToken '
                  'on a 401.',
                ),
                value: packageAuthEnabled,
                onChanged: (v) => setState(() => packageAuthEnabled = v),
              ),
              BusyButton(
                label: 'Send to echo endpoint',
                icon: Icons.send,
                onPressed: _sendEcho,
              ),
              if (_echo != null) ...[
                const SubHeading('Headers the server received'),
                KeyValueTable(_echoRows(_echo!)),
              ],
              const SubHeading('refreshTokenEndpoint'),
              KeyValueTable([
                ('refreshTokenEndpoint', '${config?.refreshTokenEndpoint}'),
              ]),
              const SizedBox(height: 6),
              Text(
                'ApiConfig.refreshTokenEndpoint documents where a new token '
                'comes from after a 401 (the response must include a "token" '
                'field). The package does not call it by itself. '
                'AuthInterceptor takes an onRefreshToken callback instead: '
                'call your refresh endpoint there and return the new token, '
                'and the failed request is retried with it.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Custom ApiInterceptor',
          subtitle:
              'DemoLogInterceptor extends ApiInterceptor and writes '
              'onRequest, onResponse and onError to the event log. It was '
              'registered once for the whole app: DioService cannot remove '
              'interceptors, so a second registration would log every call '
              'twice.',
          code:
              "class DemoLogInterceptor extends ApiInterceptor {\n  @override\n  Future<void> onRequest(options) async => log('-> \${options.uri}');\n  @override\n  Future<void> onResponse(response) async => log('<- \${response.statusCode}');\n  @override\n  Future<void> onError(error) async => log('x \${error.type}');\n}\n\nDioService.instance.addInterceptors([DemoLogInterceptor()]);",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable([
                ('registered', '$demoInterceptorsRegistered'),
                ('requests seen', '${DemoLogInterceptor.requestCount}'),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Write to the event log'),
                value: DemoLogInterceptor.logging,
                onChanged: (v) =>
                    setState(() => DemoLogInterceptor.logging = v),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  BusyButton(
                    tonal: true,
                    label: 'GET /todos/1',
                    onPressed: () async {
                      await sendDemoRequest(
                        const ApiRequest(
                          endpoint: '/todos/1',
                          method: ApiMethod.get,
                          cachePolicy: CachePolicy.networkOnly,
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  BusyButton(
                    tonal: true,
                    label: 'GET /nope (404)',
                    onPressed: () async {
                      await sendDemoRequest(
                        const ApiRequest(
                          endpoint: '/posts/99999',
                          method: ApiMethod.get,
                          cachePolicy: CachePolicy.networkOnly,
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              EventLogView(
                log: demoNetworkEvents,
                emptyText: 'Send a request to see interceptor events.',
              ),
              TextButton(
                onPressed: demoNetworkEvents.clear,
                child: const Text('Clear log'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Global callbacks',
          subtitle:
              'ApiConfig takes onUnauthorized, onSessionExpired, onUserBanned '
              'and onError. They are stored on the config; the package does '
              'not invoke them by itself. CallbackBridgeInterceptor shows the '
              'wiring: 401 calls onUnauthorized, 419 onSessionExpired, 403 '
              'onUserBanned and anything else onError.',
          code:
              "class CallbackBridgeInterceptor extends ApiInterceptor {\n  @override\n  Future<void> onError(error) async {\n    final cfg = AppController.instance.apiConfig;\n    if (error.response?.statusCode == 401) await cfg?.onUnauthorized?.call();\n  }\n}",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable([
                (
                  'onUnauthorized',
                  config?.onUnauthorized == null ? 'not set' : 'set',
                ),
                (
                  'onSessionExpired',
                  config?.onSessionExpired == null ? 'not set' : 'set',
                ),
                (
                  'onUserBanned',
                  config?.onUserBanned == null ? 'not set' : 'set',
                ),
                ('onError', config?.onError == null ? 'not set' : 'set'),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Forward errors to the callbacks'),
                value: CallbackBridgeInterceptor.enabled,
                onChanged: (v) =>
                    setState(() => CallbackBridgeInterceptor.enabled = v),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, code) in [
                    ('401 unauthorized', 401),
                    ('419 session expired', 419),
                    ('403 banned', 403),
                    ('500 error', 500),
                  ])
                    BusyButton(
                      tonal: true,
                      label: label,
                      onPressed: () => _trigger(code),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Callback lines appear in the log above.'),
            ],
          ),
        ),
        DemoSection(
          title: 'Raw Dio access',
          subtitle:
              'DioService.instance.dio is the shared Dio, for anything '
              'ApiClient does not cover.',
          code:
              "final response = await DioService.instance.dio.get('/todos/1');",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable([
                ('baseUrl', dio.options.baseUrl),
                ('connectTimeout', '${dio.options.connectTimeout}'),
                ('receiveTimeout', '${dio.options.receiveTimeout}'),
                ('sendTimeout', '${dio.options.sendTimeout}'),
                ('default headers', '${dio.options.headers}'),
                ('interceptors', '${dio.interceptors.length}'),
              ]),
              const SizedBox(height: 8),
              BusyButton(
                tonal: true,
                label: 'dio.get(/todos/1)',
                onPressed: _rawDio,
              ),
              if (_rawResult.isNotEmpty) CodeSnippet(_rawResult),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: _app,
          builder: (context, _) => DemoSection(
            title: 'Network logs',
            subtitle:
                'AppFeature.networkLogs switches the console output of the '
                'package logger at runtime. Output only appears when '
                'ApiConfig.printLogs is also true.',
            code:
                "await AppController.instance.setEnabled(AppFeature.networkLogs, false);",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('AppFeature.networkLogs'),
                  value: _app.isEnabled(AppFeature.networkLogs),
                  onChanged: (v) => _app.setEnabled(AppFeature.networkLogs, v),
                ),
                KeyValueTable([
                  (
                    'isReady(networkLogs)',
                    '${_app.isReady(AppFeature.networkLogs)}',
                  ),
                  ('ApiConfig.printLogs', '${config?.printLogs}'),
                  ('ApiConfig.enableLogs', '${config?.enableLogs}'),
                ]),
                const SizedBox(height: 6),
                Text(
                  'Run a request and watch the debug console for [REQUEST] '
                  'and [RESPONSE] lines. enableLogs is accepted by ApiConfig '
                  'but currently has no effect: printLogs and the feature '
                  'switch decide.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
