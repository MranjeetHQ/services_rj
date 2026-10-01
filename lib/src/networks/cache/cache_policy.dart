/// How [ApiClient] combines the cache and the network for a request.
enum CachePolicy {
  /// Always hit the network. Nothing is read from or written to the cache.
  networkOnly,

  /// Try the network first and store the result. If the network fails
  /// (offline, timeout, 5xx) return the last cached copy instead.
  networkFirst,

  /// Return a fresh cached copy without touching the network. If the copy
  /// is missing or expired, fetch it, and fall back to the expired copy
  /// if the network fails.
  cacheFirst,

  /// Return any usable cached copy instantly, even an expired one, and
  /// refresh it in the background. The UI never waits on the network once
  /// data has been cached. This is the default.
  staleWhileRevalidate,

  /// Only read the cache. Throws [ApiException] when nothing is cached.
  cacheOnly,
}
