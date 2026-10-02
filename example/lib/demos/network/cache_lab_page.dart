import 'dart:async';

import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

import '../../widgets/demo_widgets.dart';
import 'network_common.dart';
import 'network_logic.dart';

/// Explores every `CachePolicy`, the cache manager API and `ApiClient.watch`.
class CacheLabPage extends StatelessWidget {
  /// Creates the page.
  const CacheLabPage({super.key});

  @override
  Widget build(BuildContext context) => const FeatureGate(
    title: 'Cache lab',
    features: [AppFeature.network, AppFeature.apiCache],
    builder: _build,
  );

  static Widget _build(BuildContext context) => const _CacheLabBody();
}

const _policyNotes = {
  CachePolicy.networkOnly:
      'Always the network. Nothing is read from or written to the cache.',
  CachePolicy.networkFirst:
      'Network first and store it. Falls back to the cache if the call fails.',
  CachePolicy.cacheFirst:
      'A fresh copy is returned without any network call. Otherwise fetch.',
  CachePolicy.staleWhileRevalidate:
      'Any usable copy at once, even an expired one, and refresh in the '
      'background. The default.',
  CachePolicy.cacheOnly:
      'Cache only. Throws ApiException when nothing is cached.',
};

const _ttlChoices = <String, Duration?>{
  '3 s': Duration(seconds: 3),
  '30 s': Duration(seconds: 30),
  'Config default': null,
};

class _CacheLabBody extends StatefulWidget {
  const _CacheLabBody();

  @override
  State<_CacheLabBody> createState() => _CacheLabBodyState();
}

class _CacheLabBodyState extends State<_CacheLabBody> {
  final ApiCacheManager _cache = ApiCacheManager.instance;
  final EventLog _revalidated = EventLog();
  final EventLog _watchEvents = EventLog();

  String _endpoint = '/posts/1';
  String _ttlLabel = '3 s';
  bool _customKey = true;
  bool _forceRefresh = false;
  final Map<CachePolicy, PolicyRun> _runs = {};

  InvalidateResult? _invalidate;

  Stream<ApiResponse<dynamic>>? _watchStream;
  ApiResponse<dynamic>? _watchInitial;

  final _scope = TextEditingController();
  final _entryKey = TextEditingController();
  CacheEntry? _entry;
  String _entryNote = 'Nothing read yet.';
  String _peekNote = '';

  Duration? get _ttl => _ttlChoices[_ttlLabel];

  String? get _key => _customKey ? 'lab:$_endpoint' : null;

  ApiRequest get _sampleRequest =>
      labRequest(endpoint: _endpoint, cacheKey: _key);

  @override
  void initState() {
    super.initState();
    _scope.text = _cache.scope;
    _entryKey.text = _cache.keyFor(
      _sampleRequest,
      baseUrl: DioService.instance.dio.options.baseUrl,
    );
  }

  @override
  void dispose() {
    _scope.dispose();
    _entryKey.dispose();
    _revalidated.dispose();
    _watchEvents.dispose();
    super.dispose();
  }

  String get _baseUrl => DioService.instance.dio.options.baseUrl;

  void _refreshKey() {
    _entryKey.text = _cache.keyFor(_sampleRequest, baseUrl: _baseUrl);
  }

  Future<void> _run(CachePolicy policy) async {
    final run = await runPolicy(
      endpoint: _endpoint,
      policy: policy,
      ttl: _ttl,
      cacheKey: _key,
      forceRefresh: _forceRefresh,
      onRevalidated: (fresh) {
        if (!mounted) return;
        _revalidated.add(
          'onRevalidated: new data for $_endpoint (statusCode ${fresh.statusCode})',
        );
      },
    );
    if (mounted) setState(() => _runs[policy] = run);
  }

  Future<void> _runAll() async {
    for (final policy in CachePolicy.values) {
      await _run(policy);
      if (!mounted) return;
    }
  }

  Future<void> _prime() async {
    final run = await primeCache(
      endpoint: _endpoint,
      ttl: _ttl,
      cacheKey: _key,
    );
    if (mounted) setState(() => _runs[CachePolicy.networkFirst] = run);
  }

  Future<void> _clear() async {
    await _cache.clear();
    if (mounted) {
      setState(_runs.clear);
    }
  }

  Future<void> _runInvalidate() async {
    final result = await runInvalidateDemo(
      endpoints: const ['/posts/1', '/posts/2'],
      postEndpoint: '/posts',
      prefix: '/posts',
    );
    if (mounted) setState(() => _invalidate = result);
  }

  void _startWatch() {
    final request = labRequest(
      endpoint: _endpoint,
      cacheKey: _key,
      ttl: _ttl,
      forceRefresh: _forceRefresh,
    );
    _watchEvents.clear();
    setState(() {
      _watchInitial = ApiClient.instance.peek(request);
      _watchStream = ApiClient.instance.watch(request).map((r) {
        if (mounted) {
          _watchEvents.add(
            '${r.isFromCache ? (r.isStale ? 'stale cache' : 'cache') : 'network'}'
            ' event for $_endpoint',
          );
        }
        return r;
      });
    });
  }

  void _peek() {
    final response = ApiClient.instance.peek(_sampleRequest);
    setState(() {
      _peekNote = response == null
          ? 'peek: null (nothing in memory, the first frame would be empty)'
          : 'peek: instant ${response.isStale ? 'stale ' : ''}data cached at '
                '${response.cachedAt?.toIso8601String()}';
    });
  }

  Future<void> _readEntry() async {
    final entry = await _cache.read(_entryKey.text);
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _entryNote = entry == null
          ? 'read: null (missing, or older than maxStale)'
          : 'read: found';
    });
  }

  void _peekEntry() {
    final entry = _cache.peek(_entryKey.text);
    setState(() {
      _entry = entry;
      _entryNote = entry == null
          ? 'peek: null (not in memory)'
          : 'peek: found in memory';
    });
  }

  Future<void> _writeEntry() async {
    await _cache.write(
      _entryKey.text,
      const ApiResponse(
        success: true,
        statusCode: 200,
        data: {'written': 'by hand', 'from': 'ApiCacheManager.write'},
      ),
      endpoint: '/manual/demo',
      ttl: const Duration(seconds: 20),
    );
    await _readEntry();
  }

  Future<void> _invalidatePrefix(String prefix) async {
    final removed = await _cache.invalidate(prefix);
    if (!mounted) return;
    setState(() => _entryNote = 'invalidate("$prefix") removed $removed');
  }

  @override
  Widget build(BuildContext context) {
    final config = _cache.config;
    final stats = _cache.stats;
    return DemoPage(
      title: 'Cache lab',
      intro:
          'Responses to GET requests are cached on disk and in memory. The '
          'CachePolicy decides whether a call uses the cache, the network or '
          'both. Run the same request with each policy and compare.',
      children: [
        DemoSection(
          title: 'Policy comparison',
          subtitle:
              'Prime the cache, then run policies against the same key. With '
              'a 3 s TTL you can watch a copy go from fresh to stale.',
          code:
              "ApiRequest(\n  endpoint: '/posts/1',\n  method: ApiMethod.get,\n  cachePolicy: CachePolicy.cacheFirst,\n  cacheTtl: Duration(seconds: 30),\n  cacheKey: 'lab:/posts/1',\n  forceRefresh: false,\n  onRevalidated: (fresh) => setState(() => data = fresh.data),\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: _endpoint,
                    items: const [
                      DropdownMenuItem(
                        value: '/posts/1',
                        child: Text('/posts/1'),
                      ),
                      DropdownMenuItem(
                        value: '/users/1',
                        child: Text('/users/1'),
                      ),
                      DropdownMenuItem(
                        value: '/todos/1',
                        child: Text('/todos/1'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _endpoint = v!;
                      _refreshKey();
                    }),
                  ),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final l in _ttlChoices.keys)
                        ButtonSegment(value: l, label: Text(l)),
                    ],
                    selected: {_ttlLabel},
                    onSelectionChanged: (s) =>
                        setState(() => _ttlLabel = s.first),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Custom cacheKey'),
                subtitle: Text(
                  _customKey
                      ? 'cacheKey: "lab:$_endpoint" replaces the generated key.'
                      : 'The key is built from method, URL, query and body.',
                ),
                value: _customKey,
                onChanged: (v) => setState(() {
                  _customKey = v;
                  _refreshKey();
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('forceRefresh'),
                subtitle: const Text(
                  'Skips a fresh copy and goes to the network. The cache is '
                  'still the fallback if that fails.',
                ),
                value: _forceRefresh,
                onChanged: (v) => setState(() => _forceRefresh = v),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  BusyButton(
                    label: 'Prime cache',
                    icon: Icons.download_for_offline,
                    onPressed: _prime,
                  ),
                  BusyButton(
                    tonal: true,
                    label: 'Run all five',
                    icon: Icons.playlist_play,
                    onPressed: _runAll,
                  ),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Clear cache'),
                  ),
                ],
              ),
              const SubHeading('Run one policy'),
              for (final policy in CachePolicy.values)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('CachePolicy.${policy.name}'),
                  subtitle: Text(_policyNotes[policy]!),
                  trailing: FilledButton.tonal(
                    onPressed: () => _run(policy),
                    child: const Text('Run'),
                  ),
                ),
              const SubHeading('Results'),
              _RunTable(runs: _runs),
              const SubHeading('onRevalidated'),
              Text(
                'Called when a stale-while-revalidate background refresh '
                'brings data that differs from the cached copy.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              EventLogView(
                log: _revalidated,
                emptyText:
                    'Prime with a 3 s TTL, wait, then run staleWhileRevalidate.',
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Invalidate after a mutation',
          subtitle:
              'A successful POST with invalidateCache: [\'/posts\'] removes every '
              'cached entry whose endpoint starts with that prefix.',
          code:
              "ApiRequest(\n  endpoint: '/posts',\n  method: ApiMethod.post,\n  body: {'title': 'New'},\n  invalidateCache: ['/posts'],\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BusyButton(
                label: 'Cache two posts, then POST /posts',
                icon: Icons.cleaning_services,
                onPressed: _runInvalidate,
              ),
              if (_invalidate != null) ...[
                const SizedBox(height: 8),
                KeyValueTable([
                  for (final e in _invalidate!.cachedBefore.entries)
                    (
                      'GET ${e.key}',
                      'cached before: ${e.value}, after: '
                          '${_invalidate!.cachedAfter[e.key]}',
                    ),
                  (
                    'POST /posts',
                    _invalidate!.post.ok
                        ? 'status ${_invalidate!.post.response!.statusCode}'
                        : 'failed: ${_invalidate!.post.error}',
                  ),
                ]),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'ApiClient.watch and ApiClient.peek',
          subtitle:
              'watch emits the cached copy first, then the network response '
              'when it differs. peek returns the memory copy synchronously, '
              'handy as StreamBuilder.initialData.',
          code:
              "StreamBuilder(\n  stream: ApiClient.instance.watch(req),\n  initialData: ApiClient.instance.peek(req),\n  builder: (context, snap) => Text('\${snap.data?.data}'),\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _startWatch,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Start watch'),
                  ),
                  OutlinedButton(
                    onPressed: _peek,
                    child: const Text('peek now'),
                  ),
                ],
              ),
              if (_peekNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_peekNote),
                ),
              if (_watchStream != null)
                StreamBuilder<ApiResponse<dynamic>>(
                  stream: _watchStream,
                  initialData: _watchInitial,
                  builder: (context, snap) {
                    final r = snap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SubHeading('StreamBuilder'),
                        KeyValueTable([
                          ('connectionState', snap.connectionState.name),
                          if (snap.hasError) ('error', '${snap.error}'),
                          if (r != null) ...[
                            (
                              'latest source',
                              r.isFromCache
                                  ? (r.isStale ? 'stale cache' : 'cache')
                                  : 'network',
                            ),
                            ('cachedAt', '${r.cachedAt?.toIso8601String()}'),
                            ('data', previewData(r.data, maxChars: 240)),
                          ],
                        ]),
                      ],
                    );
                  },
                ),
              const SubHeading('Events emitted'),
              EventLogView(
                log: _watchEvents,
                emptyText: 'Start the watch to see each emission.',
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'ApiCacheManager',
          subtitle: 'Live state of ApiCacheManager.instance.',
          code:
              "final cache = ApiCacheManager.instance;\ncache.scope = userId; // separate users\nfinal key = cache.keyFor(request, baseUrl: base);\nawait cache.invalidate('/posts');\nawait cache.clear();",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable([
                ('isInitialized', '${_cache.isInitialized}'),
                ('isActive', '${_cache.isActive}'),
                ('generation', '${_cache.generation}'),
                ('memoryEntries', '${stats.memoryEntries}'),
                ('diskBytes', '${stats.diskBytes}'),
                ('scope', '"${_cache.scope}"'),
                (
                  'isCacheable(GET)',
                  '${_cache.isCacheable(labRequest(endpoint: '/x'))}',
                ),
                (
                  'isCacheable(POST)',
                  '${_cache.isCacheable(const ApiRequest(endpoint: '/x', method: ApiMethod.post))}',
                ),
                (
                  'keyFor(sample)',
                  _cache.keyFor(_sampleRequest, baseUrl: _baseUrl),
                ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ApiCacheManager.enabled'),
                subtitle: const Text(
                  'When off, isActive is false and ApiClient skips the cache. '
                  'AppController.setEnabled(AppFeature.apiCache, ...) does the '
                  'same through the controller.',
                ),
                value: _cache.isActive,
                onChanged: (v) => setState(() => _cache.enabled = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _scope,
                      decoration: const InputDecoration(
                        labelText: 'scope (for example a user id)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () => setState(() {
                      _cache.scope = _scope.text.trim();
                      _refreshKey();
                    }),
                    child: const Text('Set scope'),
                  ),
                ],
              ),
              const SubHeading('Read and write entries'),
              TextField(
                controller: _entryKey,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Cache key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _peekEntry,
                    child: const Text('peek'),
                  ),
                  OutlinedButton(
                    onPressed: _readEntry,
                    child: const Text('read'),
                  ),
                  OutlinedButton(
                    onPressed: _writeEntry,
                    child: const Text('write sample'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await _cache.remove(_entryKey.text);
                      if (mounted) setState(() => _entryNote = 'remove: done');
                    },
                    child: const Text('remove'),
                  ),
                  OutlinedButton(
                    onPressed: () => _invalidatePrefix('/posts'),
                    child: const Text('invalidate /posts'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await _cache.flush();
                      if (!mounted) return;
                      setState(
                        () => _entryNote = 'flush: disk writes finished',
                      );
                    },
                    child: const Text('flush'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_entryNote),
              if (_entry != null) ...[
                const SubHeading('CacheEntry'),
                KeyValueTable([
                  ('key', _entry!.key),
                  ('endpoint', _entry!.endpoint),
                  ('statusCode', '${_entry!.statusCode}'),
                  ('storedAt', _entry!.storedAt.toIso8601String()),
                  ('ttl', '${_entry!.ttl}'),
                  ('expiresAt', _entry!.expiresAt.toIso8601String()),
                  ('isFresh()', '${_entry!.isFresh()}'),
                  (
                    'isUsable(maxStale)',
                    '${_entry!.isUsable(config.maxStale)}',
                  ),
                  ('data', previewData(_entry!.data, maxChars: 240)),
                ]),
              ],
            ],
          ),
        ),
        DemoSection(
          title: 'CacheConfig',
          subtitle:
              'The values passed to AppController.initialize(cacheConfig: ...).',
          child: KeyValueTable([
            ('defaultPolicy', config.defaultPolicy.name),
            ('defaultTtl', '${config.defaultTtl}'),
            ('maxStale', '${config.maxStale}'),
            ('maxMemoryEntries', '${config.maxMemoryEntries}'),
            ('maxDiskBytes', '${config.maxDiskBytes}'),
            (
              'cacheableMethods',
              config.cacheableMethods.map((m) => m.name).join(', '),
            ),
            ('preloadOnStart', '${config.preloadOnStart}'),
            ('skipNetworkWhenOffline', '${config.skipNetworkWhenOffline}'),
            ('clearOnLogout', '${config.clearOnLogout}'),
            ('varyHeaders', config.varyHeaders.join(', ')),
            ('directoryName', config.directoryName),
          ]),
        ),
        DemoSection(
          title: 'Offline behaviour',
          subtitle: offlineExplanation(config),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable([
                ('AppConnectivity.enabled', '${AppConnectivity.enabled}'),
                ('AppConnectivity.isOnline', '${AppConnectivity.isOnline}'),
                (
                  'AppConnectivity.isKnownOffline',
                  '${AppConnectivity.isKnownOffline}',
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                'Try it: prime a key above, switch on airplane mode and run '
                'cacheFirst, networkFirst or staleWhileRevalidate. The cached '
                'copy comes back immediately and isStale tells you whether it '
                'was past its TTL.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => setState(() {}),
                child: const Text('Refresh values'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunTable extends StatelessWidget {
  const _RunTable({required this.runs});

  final Map<CachePolicy, PolicyRun> runs;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return Text('No runs yet.', style: Theme.of(context).textTheme.bodySmall);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Policy')),
          DataColumn(label: Text('Source')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Network calls'), numeric: true),
          DataColumn(label: Text('ms'), numeric: true),
          DataColumn(label: Text('cachedAt')),
        ],
        rows: [
          for (final policy in CachePolicy.values)
            if (runs[policy] case final run?)
              DataRow(
                cells: [
                  DataCell(Text(policy.name)),
                  DataCell(Text(run.outcome.source)),
                  DataCell(
                    Text(
                      run.outcome.ok
                          ? '${run.outcome.response!.statusCode}'
                          : run.outcome.error!.message,
                    ),
                  ),
                  DataCell(Text('${run.networkCalls}')),
                  DataCell(Text('${run.outcome.elapsed.inMilliseconds}')),
                  DataCell(
                    Text(
                      run.outcome.response?.cachedAt
                              ?.toIso8601String()
                              .substring(11, 19) ??
                          '-',
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
