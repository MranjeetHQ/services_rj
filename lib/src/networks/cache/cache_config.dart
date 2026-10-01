import '../api_methods.dart';
import 'cache_policy.dart';

/// Settings for the API cache. Pass it to [AppController.initialize].
class CacheConfig {
  const CacheConfig({
    this.defaultPolicy = CachePolicy.staleWhileRevalidate,
    this.defaultTtl = const Duration(minutes: 5),
    this.maxStale = const Duration(days: 30),
    this.maxMemoryEntries = 300,
    this.maxDiskBytes = 50 * 1024 * 1024,
    this.cacheableMethods = const {ApiMethod.get},
    this.preloadOnStart = true,
    this.skipNetworkWhenOffline = true,
    this.clearOnLogout = true,
    this.varyHeaders = const [],
    this.directoryName = 'services_rj_api_cache',
  });

  /// Policy used when a request does not set [ApiRequest.cachePolicy].
  final CachePolicy defaultPolicy;

  /// How long a cached response counts as fresh. Fresh responses are served
  /// without any network call.
  final Duration defaultTtl;

  /// How long after expiry a response may still be served as stale data
  /// while offline or while it is being refreshed. Older entries are
  /// discarded.
  final Duration maxStale;

  /// Number of responses kept in memory for instant, synchronous reads.
  final int maxMemoryEntries;

  /// Upper bound for the on-disk cache. The least recently written
  /// entries are removed when it is exceeded.
  final int maxDiskBytes;

  /// HTTP methods whose responses are cached. Only GET by default.
  final Set<ApiMethod> cacheableMethods;

  /// Load the most recent responses from disk into memory during
  /// initialization, so the first screens render cached data with no delay.
  final bool preloadOnStart;

  /// When the connectivity feature reports the device is offline, return
  /// cached data at once instead of waiting for the request to time out.
  final bool skipNetworkWhenOffline;

  /// Wipe the cache when [AuthTokenService.logout] runs, so the next user
  /// never sees the previous user's data.
  final bool clearOnLogout;

  /// Request header names whose values become part of the cache key, for
  /// example `Accept-Language`.
  final List<String> varyHeaders;

  /// Folder name inside the app support directory.
  final String directoryName;
}
