import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'network_common.dart';
import 'network_logic.dart';

/// Sends requests through `ApiClient` and shows everything that comes back.
class ApiPlaygroundPage extends StatelessWidget {
  /// Creates the page. [endpoints] is replaced by a local server in tests.
  const ApiPlaygroundPage({super.key, this.endpoints = const DemoEndpoints()});

  /// Absolute URLs used by the error, cancel, upload and download demos.
  final DemoEndpoints endpoints;

  @override
  Widget build(BuildContext context) => FeatureGate(
    title: 'API playground',
    features: const [AppFeature.network],
    builder: (_) => _PlaygroundBody(endpoints: endpoints),
  );
}

class _Preset {
  const _Preset(
    this.label,
    this.method,
    this.endpoint, {
    this.query = '',
    this.body = '',
  });

  final String label;
  final ApiMethod method;
  final String endpoint;
  final String query;
  final String body;
}

const _presets = [
  _Preset('GET /posts', ApiMethod.get, '/posts', query: '_limit=3'),
  _Preset('GET /posts/1', ApiMethod.get, '/posts/1'),
  _Preset('GET /users', ApiMethod.get, '/users', query: '_limit=2'),
  _Preset(
    'POST /posts',
    ApiMethod.post,
    '/posts',
    body: '{"title": "Hello", "body": "Sent from the playground", "userId": 1}',
  ),
  _Preset(
    'PUT /posts/1',
    ApiMethod.put,
    '/posts/1',
    body: '{"id": 1, "title": "Replaced", "body": "Full update", "userId": 1}',
  ),
  _Preset(
    'PATCH /posts/1',
    ApiMethod.patch,
    '/posts/1',
    body: '{"title": "Only the title changed"}',
  ),
  _Preset('DELETE /posts/1', ApiMethod.delete, '/posts/1'),
];

class _PlaygroundBody extends StatefulWidget {
  const _PlaygroundBody({required this.endpoints});

  final DemoEndpoints endpoints;

  @override
  State<_PlaygroundBody> createState() => _PlaygroundBodyState();
}

class _PlaygroundBodyState extends State<_PlaygroundBody> {
  final _endpoint = TextEditingController(text: '/posts/1');
  final _query = TextEditingController();
  final _headers = TextEditingController(text: 'X-Demo: services_rj');
  final _body = TextEditingController();

  ApiMethod _method = ApiMethod.get;
  bool _bypassCache = true;
  RequestOutcome? _result;
  RequestOutcome? _errorResult;
  String? _errorLabel;

  CancelRequest? _cancel;
  Future<RequestOutcome>? _cancelling;
  RequestOutcome? _cancelResult;

  RequestOutcome? _timeoutResult;
  double _timeoutSeconds = 2;

  final ValueNotifier<double?> _uploadProgress = ValueNotifier(0);
  final ValueNotifier<double?> _downloadProgress = ValueNotifier(0);
  RequestOutcome? _uploadResult;
  RequestOutcome? _downloadResult;
  String _uploadNote = '';
  String _downloadNote = '';
  bool _twoFiles = false;

  @override
  void dispose() {
    for (final c in [_endpoint, _query, _headers, _body]) {
      c.dispose();
    }
    _uploadProgress.dispose();
    _downloadProgress.dispose();
    _cancel?.cancel('page closed');
    super.dispose();
  }

  void _applyPreset(_Preset p) => setState(() {
    _method = p.method;
    _endpoint.text = p.endpoint;
    _query.text = p.query;
    _body.text = p.body;
    _result = null;
  });

  Future<void> _send() async {
    final outcome = await sendDemoRequest(
      ApiRequest(
        endpoint: _endpoint.text.trim(),
        method: _method,
        queryParameters: parseQuery(_query.text),
        headers: parseHeaders(_headers.text),
        body: parseBody(_body.text),
        cachePolicy: _bypassCache ? CachePolicy.networkOnly : null,
      ),
    );
    if (mounted) setState(() => _result = outcome);
  }

  Future<void> _runError(String label, String url) async {
    final outcome = await sendDemoRequest(
      ApiRequest(
        endpoint: url,
        method: ApiMethod.get,
        cachePolicy: CachePolicy.networkOnly,
      ),
    );
    if (!mounted) return;
    setState(() {
      _errorLabel = label;
      _errorResult = outcome;
    });
  }

  void _startSlow() {
    final started = startCancellable(widget.endpoints.slow);
    setState(() {
      _cancel = started.cancel;
      _cancelResult = null;
      _cancelling = started.outcome;
    });
    started.outcome.then((o) {
      if (!mounted || _cancelling != started.outcome) return;
      setState(() {
        _cancelResult = o;
        _cancelling = null;
        _cancel = null;
      });
    });
  }

  Future<void> _runTimeout() async {
    final outcome = await runTimeoutDemo(
      widget.endpoints.slow,
      Duration(milliseconds: (_timeoutSeconds * 1000).round()),
    );
    if (mounted) setState(() => _timeoutResult = outcome);
  }

  Future<void> _upload() async {
    _uploadProgress.value = 0;
    setState(() {
      _uploadResult = null;
      _uploadNote = '';
    });
    final files = [
      await createDemoUploadFile(),
      if (_twoFiles)
        await createDemoUploadFile(
          bytes: 32 * 1024,
          name: 'services_rj_upload_demo_2.txt',
        ),
    ];
    final size = files.fold<int>(0, (sum, f) => sum + f.lengthSync());
    final outcome = await runUpload(
      url: widget.endpoints.upload,
      files: files,
      onProgress: (p) =>
          _uploadProgress.value = progressFraction(p.sent, p.total),
    );
    if (!mounted) return;
    if (outcome.ok) _uploadProgress.value = 1;
    setState(() {
      _uploadResult = outcome;
      _uploadNote =
          'Sent ${files.length} file(s), $size bytes from the temp dir.';
    });
  }

  Future<void> _download() async {
    _downloadProgress.value = 0;
    setState(() {
      _downloadResult = null;
      _downloadNote = '';
    });
    final outcome = await runDownload(
      url: widget.endpoints.download,
      onProgress: (p) =>
          _downloadProgress.value = progressFraction(p.received, p.total),
    );
    if (!mounted) return;
    final file = File(demoDownloadPath());
    if (outcome.ok) _downloadProgress.value = 1;
    setState(() {
      _downloadResult = outcome;
      _downloadNote = file.existsSync()
          ? 'Saved ${file.lengthSync()} bytes to ${file.path}'
          : 'No file was written.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DemoPage(
      title: 'API playground',
      intro:
          'Every call goes through ApiClient.instance.request(ApiRequest(...)) '
          'against ${DioService.instance.dio.options.baseUrl}. Failures are '
          'thrown as ApiException.',
      children: [
        DemoSection(
          title: 'Request builder',
          subtitle:
              'Pick a preset or edit the fields. Query, headers and body use '
              'ApiRequest.queryParameters, headers and body.',
          code:
              "ApiRequest(\n  endpoint: '/posts',\n  method: ApiMethod.post,\n  queryParameters: {'_limit': 3},\n  headers: {'X-Demo': 'services_rj'},\n  body: {'title': 'Hello'},\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final p in _presets)
                    ActionChip(
                      label: Text(p.label),
                      onPressed: () => _applyPreset(p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<ApiMethod>(
                showSelectedIcon: false,
                segments: [
                  for (final m in ApiMethod.values)
                    ButtonSegment(value: m, label: Text(m.name.toUpperCase())),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _endpoint,
                decoration: const InputDecoration(
                  labelText: 'Endpoint',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _query,
                decoration: const InputDecoration(
                  labelText: 'Query parameters (a=1&b=2)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _headers,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Headers (one "Name: value" per line)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'JSON body',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bypass the cache'),
                subtitle: const Text(
                  'Sets cachePolicy: CachePolicy.networkOnly so you always see '
                  'the live response.',
                ),
                value: _bypassCache,
                onChanged: (v) => setState(() => _bypassCache = v),
              ),
              BusyButton(label: 'Send', icon: Icons.send, onPressed: _send),
              if (_result != null) ...[
                const SubHeading('Result'),
                _OutcomeView(_result!),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Errors become ApiException',
          subtitle:
              'ApiClient.request never returns a failed response, it throws. '
              'The getters tell you what kind of failure it was.',
          code:
              "try {\n  await ApiClient.instance.request(req);\n} on ApiException catch (e) {\n  if (e.isNotFound) showEmptyState();\n  if (e.isUnauthorized) goToLogin();\n}",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, url) in [
                    ('404 not found', '/posts/99999'),
                    ('401 unauthorized', widget.endpoints.statusUrl(401)),
                    ('422 validation', widget.endpoints.statusUrl(422)),
                    ('500 server error', widget.endpoints.statusUrl(500)),
                    ('Unreachable host', widget.endpoints.invalidHost),
                  ])
                    BusyButton(
                      tonal: true,
                      label: label,
                      onPressed: () => _runError(label, url),
                    ),
                ],
              ),
              if (_errorResult != null) ...[
                SubHeading('Result of "$_errorLabel"'),
                _OutcomeView(_errorResult!),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Cancel a request',
          subtitle:
              'Pass a CancelRequest in ApiRequest.cancelRequest, call cancel() '
              'and the pending call fails with "Request cancelled".',
          code:
              "final cancel = CancelRequest();\nfinal future = ApiClient.instance.request(\n  ApiRequest(endpoint: url, method: ApiMethod.get, cancelRequest: cancel),\n);\ncancel.cancel('user pressed stop');",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _cancelling == null ? _startSlow : null,
                    icon: const Icon(Icons.hourglass_bottom, size: 18),
                    label: const Text('Start slow request'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _cancel == null
                        ? null
                        : () => _cancel!.cancel('Stopped from the demo'),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
              if (_cancelling != null)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_cancelResult != null) ...[
                const SubHeading('Result'),
                _OutcomeView(_cancelResult!),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Timeouts',
          subtitle:
              'Timeouts come from ApiConfig (connectTimeout, receiveTimeout, '
              'sendTimeout, in milliseconds) and are stored on the Dio '
              'options. This demo shortens receiveTimeout for one call.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable([
                (
                  'connectTimeout',
                  '${DioService.instance.dio.options.connectTimeout}',
                ),
                (
                  'receiveTimeout',
                  '${DioService.instance.dio.options.receiveTimeout}',
                ),
                (
                  'sendTimeout',
                  '${DioService.instance.dio.options.sendTimeout}',
                ),
              ]),
              Row(
                children: [
                  Text(
                    'Timeout: ${_timeoutSeconds.toStringAsFixed(0)} s',
                    style: text.bodyMedium,
                  ),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 5,
                      divisions: 4,
                      value: _timeoutSeconds,
                      onChanged: (v) => setState(() => _timeoutSeconds = v),
                    ),
                  ),
                ],
              ),
              BusyButton(
                label: 'Call the slow endpoint',
                icon: Icons.timer_outlined,
                onPressed: _runTimeout,
              ),
              if (_timeoutResult != null) ...[
                const SubHeading('Result'),
                _OutcomeView(_timeoutResult!),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Enums',
          subtitle: 'ApiMethod and RequestType pick how a request is sent.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final m in ApiMethod.values)
                    Chip(label: Text('ApiMethod.${m.name}')),
                ],
              ),
              const SizedBox(height: 8),
              const KeyValueTable([
                ('RequestType.normal', 'JSON request, the default'),
                (
                  'RequestType.upload',
                  'Multipart POST from filePath or files, with onUploadProgress',
                ),
                (
                  'RequestType.download',
                  'Streams to downloadSavePath, with onDownloadProgress',
                ),
              ]),
            ],
          ),
        ),
        DemoSection(
          title: 'Upload with progress',
          subtitle:
              'RequestType.upload writes a temporary file and posts it as '
              'multipart form data to ${widget.endpoints.upload}.',
          code:
              "ApiRequest(\n  endpoint: url,\n  method: ApiMethod.post,\n  requestType: RequestType.upload,\n  filePath: file.path,\n  onUploadProgress: (p) => print(p.percentage),\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Send two files'),
                subtitle: const Text(
                  'Uses ApiRequest.files instead of filePath.',
                ),
                value: _twoFiles,
                onChanged: (v) => setState(() => _twoFiles = v),
              ),
              BusyButton(
                label: 'Upload',
                icon: Icons.upload_file,
                onPressed: _upload,
              ),
              const SizedBox(height: 12),
              _ProgressBar(notifier: _uploadProgress),
              if (_uploadNote.isNotEmpty) Text(_uploadNote),
              if (_uploadResult != null) ...[
                const SubHeading('Result'),
                _OutcomeView(_uploadResult!),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Download with progress',
          subtitle:
              'RequestType.download saves ${widget.endpoints.download} to the '
              'temp directory and returns the path as data.',
          code:
              "ApiRequest(\n  endpoint: url,\n  method: ApiMethod.get,\n  requestType: RequestType.download,\n  downloadSavePath: path,\n  onDownloadProgress: (p) => print(p.percentage),\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BusyButton(
                label: 'Download',
                icon: Icons.download,
                onPressed: _download,
              ),
              const SizedBox(height: 12),
              _ProgressBar(notifier: _downloadProgress),
              if (_downloadNote.isNotEmpty) Text(_downloadNote),
              if (_downloadResult != null) ...[
                const SubHeading('Result'),
                _OutcomeView(_downloadResult!),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'Network events',
          subtitle:
              'What the demo interceptor saw (see the Auth and interceptors page).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventLogView(
                log: demoNetworkEvents,
                emptyText: 'Send a request to see events.',
              ),
              TextButton(
                onPressed: demoNetworkEvents.clear,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.notifier});

  final ValueNotifier<double?> notifier;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double?>(
    valueListenable: notifier,
    builder: (context, value, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: value),
        const SizedBox(height: 4),
        Text(
          value == null
              ? 'Total size unknown (no Content-Length)'
              : '${(value * 100).toStringAsFixed(0)} %',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _OutcomeView extends StatelessWidget {
  const _OutcomeView(this.outcome);

  final RequestOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final r = outcome.response;
    final e = outcome.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              outcome.ok ? Icons.check_circle : Icons.error,
              size: 18,
              color: outcome.ok
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${outcome.ok ? 'ApiResponse' : 'ApiException'} in '
                '${outcome.elapsed.inMilliseconds} ms (${outcome.source})',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        KeyValueTable(r != null ? responseRows(r) : exceptionRows(e!)),
      ],
    );
  }
}
