import 'dart:convert';
import 'dart:io';

import '../../core/security/app_encryption.dart';
import '../api_methods.dart';
import '../api_request.dart';
import '../api_response.dart';
import 'api_cache_store.dart';
import 'cache_config.dart';
import 'cache_entry.dart';

/// Central access point for the API response cache.
///
/// [ApiClient] uses it automatically. Apps call it directly to read
/// cached data synchronously, invalidate entries, or wipe the cache.
class ApiCacheManager {
  ApiCacheManager._();

  static final ApiCacheManager instance = ApiCacheManager._();

  CacheConfig _config = const CacheConfig();

  ApiCacheStore? _store;

  bool _enabled = true;

  int _generation = 0;

  /// Increases on every [clear]. Responses fetched before a clear are
  /// dropped instead of being written back.
  int get generation => _generation;

  CacheConfig get config => _config;

  bool get isInitialized => _store != null;

  /// Whether requests currently use the cache. Controlled by
  /// [AppController] through the `apiCache` feature.
  bool get isActive => _enabled && _store != null;

  set enabled(bool value) => _enabled = value;

  /// Separates cached data per user or tenant. Set it to the user id after
  /// login so two accounts on one device never share cached responses.
  String scope = '';

  Future<void> initialize(
    CacheConfig config, {
    Directory? directoryOverride,
  }) async {
    if (_store != null) return;

    _config = config;
    final store = ApiCacheStore(
      maxMemoryEntries: config.maxMemoryEntries,
      maxDiskBytes: config.maxDiskBytes,
      directoryName: config.directoryName,
      directoryOverride: directoryOverride,
    );
    await store.initialize(preload: config.preloadOnStart);
    _store = store;
  }

  /// Drops the in-memory state so [initialize] can run again. Disk data stays.
  void reset() {
    _store = null;
    scope = '';
    _enabled = true;
  }

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------

  bool isCacheable(ApiRequest request) =>
      _config.cacheableMethods.contains(request.method);

  /// Builds the cache key for [request]. Uses [ApiRequest.cacheKey] when set.
  String keyFor(ApiRequest request, {String baseUrl = ''}) {
    final custom = request.cacheKey;
    if (custom != null) return '$scope|custom|$custom';

    final query = request.queryParameters == null
        ? ''
        : (request.queryParameters!.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key)))
              .map((e) => '${e.key}=${e.value}')
              .join('&');

    final body = request.method == ApiMethod.get || request.body == null
        ? ''
        : AppEncryption.sha256Hex(_stableEncode(request.body));

    final vary = _config.varyHeaders
        .map((h) => '$h=${request.headers?[h] ?? ''}')
        .join(',');

    return [
      scope,
      request.method.name,
      '$baseUrl${request.endpoint}',
      query,
      body,
      vary,
    ].join('|');
  }

  // ---------------------------------------------------------------------------
  // Read / write
  // ---------------------------------------------------------------------------

  /// Synchronous memory lookup for an instant first frame, for example as
  /// `initialData` of a `FutureBuilder`. Returns `null` for expired
  /// entries past [CacheConfig.maxStale].
  CacheEntry? peek(String key) {
    final entry = _store?.peek(key);
    return entry != null && entry.isUsable(_config.maxStale) ? entry : null;
  }

  /// Memory first, then disk. Entries past [CacheConfig.maxStale] are
  /// removed and `null` is returned.
  Future<CacheEntry?> read(String key) async {
    final store = _store;
    if (store == null) return null;

    final entry = await store.get(key);
    if (entry == null) return null;

    if (!entry.isUsable(_config.maxStale)) {
      await store.remove(key);
      return null;
    }
    return entry;
  }

  /// Caches a successful response. Values that cannot be encoded as JSON,
  /// such as raw bytes, are skipped.
  Future<void> write(
    String key,
    ApiResponse<dynamic> response, {
    required String endpoint,
    Duration? ttl,
    int? generation,
  }) async {
    final store = _store;
    if (store == null) return;
    if (generation != null && generation != _generation) return;

    try {
      jsonEncode(response.data);
    } catch (_) {
      return;
    }

    await store.put(
      CacheEntry(
        key: key,
        endpoint: endpoint,
        data: response.data,
        statusCode: response.statusCode,
        storedAt: DateTime.now(),
        ttl: ttl ?? _config.defaultTtl,
      ),
    );
  }

  Future<void> remove(String key) async => _store?.remove(key);

  /// Removes every entry whose endpoint starts with [endpointPrefix],
  /// for example `/posts` after creating a post.
  Future<int> invalidate(String endpointPrefix) async {
    final store = _store;
    if (store == null) return 0;

    final matches = (await store.all()).where(
      (e) => e.endpoint.startsWith(endpointPrefix),
    );
    var count = 0;
    for (final e in matches) {
      await store.remove(e.key);
      count++;
    }
    return count;
  }

  /// Removes all cached responses from memory and disk.
  Future<void> clear() async {
    _generation++;
    await _store?.clear();
  }

  /// Waits until pending disk writes are finished.
  Future<void> flush() async => _store?.flush();

  /// Counts for debugging and settings screens.
  ({int memoryEntries, int diskBytes}) get stats => (
    memoryEntries: _store?.memoryCount ?? 0,
    diskBytes: _store?.diskBytes ?? 0,
  );

  static String _stableEncode(dynamic value) {
    dynamic sort(dynamic v) {
      if (v is Map) {
        final keys = v.keys.map((k) => k.toString()).toList()..sort();
        return {for (final k in keys) k: sort(v[k])};
      }
      if (v is List) return v.map(sort).toList();
      return v;
    }

    try {
      return jsonEncode(sort(value));
    } catch (_) {
      return value.toString();
    }
  }
}
