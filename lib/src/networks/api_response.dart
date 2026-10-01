class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.isFromCache = false,
    this.isStale = false,
    this.cachedAt,
  });

  final bool success;

  final T? data;

  final String? message;

  final int? statusCode;

  /// Whether this response came from the local cache instead of the network.
  final bool isFromCache;

  /// Whether the cached data is past its TTL. A background refresh may be
  /// running, see [ApiRequest.onRevalidated] and [ApiClient.watch].
  final bool isStale;

  /// When the cached copy was stored. `null` for network responses.
  final DateTime? cachedAt;
}
