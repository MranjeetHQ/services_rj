import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:services_rj/services_rj.dart';

import 'demo_interceptors.dart';

/// Absolute URLs the demos call besides the configured `baseUrl`.
///
/// Dio ignores `baseUrl` for absolute URLs, so these can point to another
/// host. Tests swap them for a loopback server with [DemoEndpoints.local].
class DemoEndpoints {
  /// Creates a set of endpoints. Defaults use httpbin.org.
  const DemoEndpoints({
    this.echoHeaders = 'https://httpbin.org/headers',
    this.slow = 'https://httpbin.org/delay/8',
    this.upload = 'https://httpbin.org/post',
    this.download = 'https://httpbin.org/bytes/20000',
    this.status = 'https://httpbin.org/status',
    this.invalidHost = 'https://no-such-host.invalid/posts',
  });

  /// Endpoints served by a server on `127.0.0.1:[port]`.
  factory DemoEndpoints.local(int port) {
    final base = 'http://127.0.0.1:$port';
    return DemoEndpoints(
      echoHeaders: '$base/headers',
      slow: '$base/slow',
      upload: '$base/upload',
      download: '$base/bytes',
      status: '$base/status',
      invalidHost: 'http://127.0.0.1:1/posts',
    );
  }

  /// Returns the request headers it received as `{"headers": {...}}`.
  final String echoHeaders;

  /// Answers after several seconds, for cancellation and timeouts.
  final String slow;

  /// Accepts a multipart POST.
  final String upload;

  /// Serves a small binary file.
  final String download;

  /// `status/<code>` answers with that status code.
  final String status;

  /// A host that cannot be reached.
  final String invalidHost;

  /// URL that answers with [code].
  String statusUrl(int code) => '$status/$code';
}

/// Result of one demo request: a response or an exception, plus timing.
class RequestOutcome {
  /// Creates an outcome.
  const RequestOutcome({this.response, this.error, required this.elapsed});

  /// Set when the request succeeded.
  final ApiResponse<dynamic>? response;

  /// Set when the request failed.
  final ApiException? error;

  /// How long the call took.
  final Duration elapsed;

  /// Whether the request succeeded.
  bool get ok => response != null;

  /// `network`, `cache`, `stale cache` or `error`.
  String get source {
    final r = response;
    if (r == null) return 'error';
    if (!r.isFromCache) return 'network';
    return r.isStale ? 'stale cache' : 'cache';
  }
}

/// Sends [request] through [ApiClient] and captures the result.
Future<RequestOutcome> sendDemoRequest(ApiRequest request) async {
  ensureDemoInterceptors();
  final watch = Stopwatch()..start();
  try {
    final response = await ApiClient.instance.request(request);
    return RequestOutcome(response: response, elapsed: watch.elapsed);
  } on ApiException catch (e) {
    return RequestOutcome(error: e, elapsed: watch.elapsed);
  }
}

/// Every [ApiResponse] field as label and value rows.
List<(String, String)> responseRows(ApiResponse<dynamic> r) => [
  ('success', '${r.success}'),
  ('statusCode', '${r.statusCode}'),
  ('message', '${r.message}'),
  ('isFromCache', '${r.isFromCache}'),
  ('isStale', '${r.isStale}'),
  ('cachedAt', '${r.cachedAt?.toIso8601String()}'),
  ('data', previewData(r.data)),
];

/// Every [ApiException] getter as label and value rows.
List<(String, String)> exceptionRows(ApiException e) => [
  ('message', e.message),
  ('statusCode', '${e.statusCode}'),
  ('isUnauthorized', '${e.isUnauthorized}'),
  ('isValidationError', '${e.isValidationError}'),
  ('isServerError', '${e.isServerError}'),
  ('isNotFound', '${e.isNotFound}'),
  ('data', previewData(e.data)),
  ('toString()', e.toString()),
];

/// Pretty-printed JSON of [data], cut to [maxChars].
String previewData(dynamic data, {int maxChars = 700}) {
  if (data == null) return 'null';
  String text;
  try {
    text = data is String
        ? data
        : const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    text = data.toString();
  }
  return text.length <= maxChars
      ? text
      : '${text.substring(0, maxChars)}\n... (${text.length - maxChars} more characters)';
}

/// Parses `a=1&b=2` (or one pair per line) into query parameters.
Map<String, dynamic>? parseQuery(String text) {
  final result = <String, dynamic>{};
  for (final part in text.split(RegExp(r'[&\n]'))) {
    final pair = part.trim();
    if (pair.isEmpty) continue;
    final i = pair.indexOf('=');
    if (i < 0) {
      result[pair] = '';
    } else {
      result[pair.substring(0, i).trim()] = pair.substring(i + 1).trim();
    }
  }
  return result.isEmpty ? null : result;
}

/// Parses `Name: value` lines into headers.
Map<String, dynamic>? parseHeaders(String text) {
  final result = <String, dynamic>{};
  for (final line in text.split('\n')) {
    final i = line.indexOf(':');
    if (i <= 0) continue;
    result[line.substring(0, i).trim()] = line.substring(i + 1).trim();
  }
  return result.isEmpty ? null : result;
}

/// Decodes [text] as JSON, or sends it as a plain string when it is not JSON.
dynamic parseBody(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  try {
    return jsonDecode(t);
  } catch (_) {
    return t;
  }
}

// -----------------------------------------------------------------------------
// Cancel and timeout
// -----------------------------------------------------------------------------

/// Starts a slow GET that can be stopped through the returned
/// [CancelRequest].
({CancelRequest cancel, Future<RequestOutcome> outcome}) startCancellable(
  String url,
) {
  final cancel = CancelRequest();
  final outcome = sendDemoRequest(
    ApiRequest(
      endpoint: url,
      method: ApiMethod.get,
      cancelRequest: cancel,
      cachePolicy: CachePolicy.networkOnly,
    ),
  );
  return (cancel: cancel, outcome: outcome);
}

/// Calls [url] with a shortened receive timeout on the shared Dio and
/// restores the old value afterwards.
///
/// [ApiRequest] has no timeout field; timeouts live in [ApiConfig] and on
/// `DioService.instance.dio.options`.
Future<RequestOutcome> runTimeoutDemo(String url, Duration timeout) async {
  final options = DioService.instance.dio.options;
  final previous = options.receiveTimeout;
  options.receiveTimeout = timeout;
  try {
    return await sendDemoRequest(
      ApiRequest(
        endpoint: url,
        method: ApiMethod.get,
        cachePolicy: CachePolicy.networkOnly,
      ),
    );
  } finally {
    options.receiveTimeout = previous;
  }
}

// -----------------------------------------------------------------------------
// Upload and download
// -----------------------------------------------------------------------------

/// Writes a small text file to the temp directory for the upload demo.
Future<File> createDemoUploadFile({
  int bytes = 96 * 1024,
  String name = 'services_rj_upload_demo.txt',
}) async {
  final file = File('${Directory.systemTemp.path}/$name');
  const line = 'services_rj upload demo line - original sample content\n';
  final buffer = StringBuffer();
  while (buffer.length < bytes) {
    buffer.write(line);
  }
  await file.writeAsString(buffer.toString());
  return file;
}

/// Uploads [files] as multipart form data with [ApiMethod.post].
///
/// One file goes through `filePath`, several through `files`.
Future<RequestOutcome> runUpload({
  required String url,
  required List<File> files,
  void Function(UploadProgress progress)? onProgress,
  CancelRequest? cancel,
}) {
  return sendDemoRequest(
    ApiRequest(
      endpoint: url,
      method: ApiMethod.post,
      requestType: RequestType.upload,
      filePath: files.length == 1 ? files.single.path : null,
      files: files.length > 1 ? files : null,
      fileField: 'file',
      body: const {'note': 'services_rj demo upload'},
      onUploadProgress: onProgress,
      cancelRequest: cancel,
    ),
  );
}

/// Path of the file written by the download demo.
String demoDownloadPath() =>
    '${Directory.systemTemp.path}/services_rj_download_demo.bin';

/// Downloads [url] to [demoDownloadPath]. The response `data` is the path.
Future<RequestOutcome> runDownload({
  required String url,
  void Function(DownloadProgress progress)? onProgress,
  CancelRequest? cancel,
}) async {
  final target = File(demoDownloadPath());
  if (target.existsSync()) await target.delete();
  return sendDemoRequest(
    ApiRequest(
      endpoint: url,
      method: ApiMethod.get,
      requestType: RequestType.download,
      downloadSavePath: target.path,
      onDownloadProgress: onProgress,
      cancelRequest: cancel,
    ),
  );
}

/// Progress as a 0..1 fraction. Servers that send no `Content-Length` report
/// a total of -1, which [UploadProgress.percentage] turns into a negative
/// number, so this returns `null` (indeterminate) instead.
double? progressFraction(int done, int total) =>
    total <= 0 ? null : (done / total).clamp(0.0, 1.0);

// -----------------------------------------------------------------------------
// Cache lab
// -----------------------------------------------------------------------------

/// One run of a request with a given [CachePolicy].
class PolicyRun {
  /// Creates a run record.
  const PolicyRun({
    required this.policy,
    required this.outcome,
    required this.networkCalls,
    required this.forceRefresh,
    required this.cacheKey,
  });

  /// Policy used.
  final CachePolicy policy;

  /// What came back.
  final RequestOutcome outcome;

  /// Requests that reached the network while the call ran. A background
  /// refresh that starts later is not included.
  final int networkCalls;

  /// Whether `forceRefresh` was set.
  final bool forceRefresh;

  /// Custom cache key, if any.
  final String? cacheKey;
}

/// Builds a GET request for the cache lab.
ApiRequest labRequest({
  required String endpoint,
  CachePolicy? policy,
  Duration? ttl,
  String? cacheKey,
  bool forceRefresh = false,
  Map<String, dynamic>? query,
  void Function(ApiResponse<dynamic> fresh)? onRevalidated,
}) => ApiRequest(
  endpoint: endpoint,
  method: ApiMethod.get,
  queryParameters: query,
  cachePolicy: policy,
  cacheTtl: ttl,
  cacheKey: cacheKey,
  forceRefresh: forceRefresh,
  onRevalidated: onRevalidated,
);

/// Runs a GET with [policy] and records the source and the number of
/// network calls.
Future<PolicyRun> runPolicy({
  required String endpoint,
  required CachePolicy policy,
  Duration? ttl,
  String? cacheKey,
  bool forceRefresh = false,
  void Function(ApiResponse<dynamic> fresh)? onRevalidated,
}) async {
  ensureDemoInterceptors();
  final before = DemoLogInterceptor.requestCount;
  final outcome = await sendDemoRequest(
    labRequest(
      endpoint: endpoint,
      policy: policy,
      ttl: ttl,
      cacheKey: cacheKey,
      forceRefresh: forceRefresh,
      onRevalidated: onRevalidated,
    ),
  );
  return PolicyRun(
    policy: policy,
    outcome: outcome,
    networkCalls: DemoLogInterceptor.requestCount - before,
    forceRefresh: forceRefresh,
    cacheKey: cacheKey,
  );
}

/// Stores a fresh copy of [endpoint] so the policies have something to read.
Future<PolicyRun> primeCache({
  required String endpoint,
  Duration? ttl,
  String? cacheKey,
}) => runPolicy(
  endpoint: endpoint,
  policy: CachePolicy.networkFirst,
  ttl: ttl,
  cacheKey: cacheKey,
  forceRefresh: true,
);

/// Whether a cached copy of [request] sits in memory right now.
bool isCachedInMemory(ApiRequest request) =>
    ApiClient.instance.peek(request) != null;

/// Result of the invalidate-after-POST demonstration.
class InvalidateResult {
  /// Creates a result.
  const InvalidateResult({
    required this.cachedBefore,
    required this.cachedAfter,
    required this.post,
  });

  /// Which GETs were cached before the POST.
  final Map<String, bool> cachedBefore;

  /// Which GETs were cached after the POST.
  final Map<String, bool> cachedAfter;

  /// The POST outcome.
  final RequestOutcome post;
}

/// Caches GETs for [endpoints], then POSTs to [postEndpoint] with
/// `invalidateCache: [prefix]` and reports which GETs survived.
Future<InvalidateResult> runInvalidateDemo({
  required List<String> endpoints,
  required String postEndpoint,
  required String prefix,
}) async {
  for (final e in endpoints) {
    await primeCache(endpoint: e);
  }
  bool cached(String e) => isCachedInMemory(labRequest(endpoint: e));
  final before = {for (final e in endpoints) e: cached(e)};
  final post = await sendDemoRequest(
    ApiRequest(
      endpoint: postEndpoint,
      method: ApiMethod.post,
      body: const {'title': 'cache demo', 'body': 'created by the cache lab'},
      invalidateCache: [prefix],
    ),
  );
  final after = {for (final e in endpoints) e: cached(e)};
  return InvalidateResult(cachedBefore: before, cachedAfter: after, post: post);
}

/// Explains the offline behaviour in one place so UI and docs agree.
String offlineExplanation(CacheConfig config) => config.skipNetworkWhenOffline
    ? 'skipNetworkWhenOffline is on: when AppConnectivity reports the '
          'device offline and a cached copy exists, ApiClient answers from '
          'the cache at once instead of waiting for a timeout, whatever '
          'the policy. Without a cached copy the request still tries the '
          'network and fails.'
    : 'skipNetworkWhenOffline is off: requests always try the network. '
          'networkFirst, cacheFirst and staleWhileRevalidate still fall '
          'back to the cache when the call fails.';
