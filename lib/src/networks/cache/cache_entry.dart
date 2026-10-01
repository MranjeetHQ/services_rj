/// A cached API response.
class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.endpoint,
    required this.data,
    required this.statusCode,
    required this.storedAt,
    required this.ttl,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['k'] as String,
      endpoint: json['e'] as String,
      data: json['d'],
      statusCode: json['s'] as int?,
      storedAt: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
      ttl: Duration(milliseconds: json['ttl'] as int),
    );
  }

  final String key;

  /// Endpoint path, used to invalidate related entries after a mutation.
  final String endpoint;

  final dynamic data;

  final int? statusCode;

  final DateTime storedAt;

  final Duration ttl;

  DateTime get expiresAt => storedAt.add(ttl);

  bool isFresh([DateTime? now]) => (now ?? DateTime.now()).isBefore(expiresAt);

  /// Whether the entry may still be served, fresh or stale.
  bool isUsable(Duration maxStale, [DateTime? now]) =>
      (now ?? DateTime.now()).isBefore(expiresAt.add(maxStale));

  Map<String, dynamic> toJson() => {
    'k': key,
    'e': endpoint,
    'd': data,
    's': statusCode,
    't': storedAt.millisecondsSinceEpoch,
    'ttl': ttl.inMilliseconds,
  };
}
