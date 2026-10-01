import 'dart:io';

import 'api_methods.dart';
import 'api_response.dart';
import 'cache/cache_policy.dart';
import 'cancel_request.dart';
import 'models/download_progress.dart';
import 'models/upload_progress.dart';
import 'request_type.dart';

class ApiRequest {
  const ApiRequest({
    required this.endpoint,
    required this.method,

    this.requestType = RequestType.normal,

    this.body,
    this.queryParameters,
    this.headers,

    this.filePath,
    this.files,
    this.fileField = 'file',

    this.downloadSavePath,

    this.onUploadProgress,
    this.onDownloadProgress,

    this.cancelRequest,

    this.cachePolicy,
    this.cacheTtl,
    this.cacheKey,
    this.forceRefresh = false,
    this.invalidateCache,
    this.onRevalidated,
  });

  final String endpoint;

  final ApiMethod method;

  final RequestType requestType;

  final dynamic body;

  final Map<String, dynamic>? queryParameters;

  final Map<String, dynamic>? headers;

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  final String? filePath;

  final List<File>? files;

  final String fileField;

  // ---------------------------------------------------------------------------
  // Download
  // ---------------------------------------------------------------------------

  final String? downloadSavePath;

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  final void Function(UploadProgress progress)? onUploadProgress;

  final void Function(DownloadProgress progress)? onDownloadProgress;

  // ---------------------------------------------------------------------------
  // Cancellation
  // ---------------------------------------------------------------------------

  final CancelRequest? cancelRequest;

  // ---------------------------------------------------------------------------
  // Caching (GET only by default, see CacheConfig.cacheableMethods)
  // ---------------------------------------------------------------------------

  /// Overrides [CacheConfig.defaultPolicy] for this request.
  final CachePolicy? cachePolicy;

  /// Overrides [CacheConfig.defaultTtl] for this request.
  final Duration? cacheTtl;

  /// Custom cache key. By default the key is built from the method, URL,
  /// sorted query parameters and body.
  final String? cacheKey;

  /// Skip a fresh cached copy and go to the network. The cache is still
  /// used as a fallback if the network fails.
  final bool forceRefresh;

  /// Endpoint prefixes whose cached entries are removed after this request
  /// succeeds, for example `['/posts']` after a POST to `/posts`.
  final List<String>? invalidateCache;

  /// Called when a stale-while-revalidate background refresh brings new data.
  final void Function(ApiResponse<dynamic> fresh)? onRevalidated;
}
