import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/app_connectivity.dart';
import '../core/app_logger.dart';
import 'api_exception.dart';
import 'api_methods.dart';
import 'api_request.dart';
import 'api_response.dart';
import 'dio_service.dart';
import 'handlers/exception_handler.dart';
import 'handlers/response_handler.dart';
import 'models/download_progress.dart';
import 'models/upload_progress.dart';
import 'request_type.dart';
import 'cache/api_cache_manager.dart';
import 'cache/cache_entry.dart';
import 'cache/cache_policy.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  Dio get _dio => DioService.instance.dio;

  ApiCacheManager get _cache => ApiCacheManager.instance;

  /// Requests currently being fetched, keyed by cache key, so identical
  /// requests share one network call.
  final Map<String, Future<ApiResponse<dynamic>>> _inFlight = {};

  // ---------------------------------------------------------------------------
  // COMMON REQUEST METHOD
  // ---------------------------------------------------------------------------

  /// Sends [request]. Cacheable requests follow their [CachePolicy]; see
  /// [ApiResponse.isFromCache] and [ApiResponse.isStale] on the result.
  Future<ApiResponse<dynamic>> request(ApiRequest request) async {
    if (_cacheApplies(request)) {
      return _cachedRequest(request, _keyFor(request));
    }

    try {
      final response = await _send(request);
      await _invalidateAfter(request);
      return response;
    } catch (e, stackTrace) {
      throw ExceptionHandler.handle(e, stackTrace: stackTrace);
    }
  }

  /// Emits the cached response right away (if any), then the network
  /// response when it differs. Use it with a `StreamBuilder` for screens that
  /// should show data instantly and update when fresh data arrives.
  ///
  /// The network is skipped while the cached copy is still fresh, unless
  /// [ApiRequest.forceRefresh] is set.
  Stream<ApiResponse<dynamic>> watch(ApiRequest request) async* {
    if (!_cacheApplies(request)) {
      yield await this.request(request);
      return;
    }

    final key = _keyFor(request);
    final cached = await _cache.read(key);

    if (cached != null) {
      yield _fromEntry(cached);
      if (!request.forceRefresh && cached.isFresh()) return;
      if (_isOffline) return;
    }

    try {
      final fresh = await _fetchAndStore(request, key);
      if (cached == null || !_sameData(cached.data, fresh.data)) {
        yield fresh;
      }
    } catch (e, stackTrace) {
      if (cached == null) {
        throw ExceptionHandler.handle(e, stackTrace: stackTrace);
      }
      AppLogger.warning(
        'ApiClient.watch refresh failed, keeping cached data: $e',
      );
    }
  }

  /// Returns the cached response from memory without awaiting anything, or
  /// `null`. Handy as `initialData` so the first frame already has content.
  ApiResponse<dynamic>? peek(ApiRequest request) {
    if (!_cacheApplies(request)) return null;
    final entry = _cache.peek(_keyFor(request));
    return entry == null ? null : _fromEntry(entry);
  }

  // ---------------------------------------------------------------------------
  // CACHE FLOW
  // ---------------------------------------------------------------------------

  bool _cacheApplies(ApiRequest request) =>
      _cache.isActive &&
      request.requestType == RequestType.normal &&
      _cache.isCacheable(request) &&
      (request.cachePolicy ?? _cache.config.defaultPolicy) !=
          CachePolicy.networkOnly;

  String _keyFor(ApiRequest request) =>
      _cache.keyFor(request, baseUrl: _dio.options.baseUrl);

  bool get _isOffline =>
      _cache.config.skipNetworkWhenOffline && AppConnectivity.isKnownOffline;

  Future<ApiResponse<dynamic>> _cachedRequest(
    ApiRequest request,
    String key,
  ) async {
    final policy = request.cachePolicy ?? _cache.config.defaultPolicy;
    final cached = await _cache.read(key);

    // Offline with data on hand: answer instantly instead of timing out.
    if (cached != null && _isOffline) return _fromEntry(cached);

    switch (policy) {
      case CachePolicy.cacheOnly:
        if (cached != null) return _fromEntry(cached);
        throw ApiException(message: 'No cached data for ${request.endpoint}');

      case CachePolicy.staleWhileRevalidate:
        if (cached != null && !request.forceRefresh) {
          if (!cached.isFresh()) _revalidate(request, key, cached);
          return _fromEntry(cached);
        }
        return _fetchWithFallback(request, key, cached);

      case CachePolicy.cacheFirst:
        if (cached != null && cached.isFresh() && !request.forceRefresh) {
          return _fromEntry(cached);
        }
        return _fetchWithFallback(request, key, cached);

      case CachePolicy.networkFirst:
      case CachePolicy.networkOnly:
        return _fetchWithFallback(request, key, cached);
    }
  }

  Future<ApiResponse<dynamic>> _fetchWithFallback(
    ApiRequest request,
    String key,
    CacheEntry? fallback,
  ) async {
    try {
      return await _fetchAndStore(request, key);
    } on DioException catch (e, stackTrace) {
      if (fallback != null && _canFallBack(e)) {
        AppLogger.warning(
          'ApiClient: network failed, serving cached ${request.endpoint}',
        );
        return _fromEntry(fallback);
      }
      throw ExceptionHandler.handle(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw ExceptionHandler.handle(e, stackTrace: stackTrace);
    }
  }

  /// Fetches from the network and stores the result.
  ///
  /// Concurrent calls with the same key share one request, except calls
  /// that carry their own [CancelRequest]: cancelling one screen's request
  /// must never cancel another screen's.
  ///
  /// The cache generation is captured before the request starts. If the
  /// cache is cleared meanwhile (logout), the late response is not written
  /// back and is not shared with requests made after the clear.
  Future<ApiResponse<dynamic>> _fetchAndStore(ApiRequest request, String key) {
    final generation = _cache.generation;

    Future<ApiResponse<dynamic>> run() async {
      final response = await _send(request);
      await _cache.write(
        key,
        response,
        endpoint: request.endpoint,
        ttl: request.cacheTtl,
        generation: generation,
      );
      await _invalidateAfter(request);
      return response;
    }

    if (request.cancelRequest != null) return run();

    final flightKey = '$generation|$key';
    // The callback must not return the removed future: whenComplete would
    // then wait on itself and never finish.
    return _inFlight[flightKey] ??= run().whenComplete(() {
      _inFlight.remove(flightKey);
    });
  }

  void _revalidate(ApiRequest request, String key, CacheEntry cached) {
    _fetchAndStore(request, key).then(
      (fresh) {
        if (!_sameData(cached.data, fresh.data)) {
          request.onRevalidated?.call(fresh);
        }
      },
      onError: (Object e) {
        AppLogger.warning(
          'ApiClient: background refresh of ${request.endpoint} failed: $e',
        );
      },
    );
  }

  /// Network-level failures where stale data beats an error screen.
  bool _canFallBack(DioException e) {
    if (e.type == DioExceptionType.cancel) return false;
    final status = e.response?.statusCode;
    return status == null || status >= 500 || status == 408 || status == 429;
  }

  ApiResponse<dynamic> _fromEntry(CacheEntry entry) => ApiResponse(
    success: true,
    data: entry.data,
    statusCode: entry.statusCode,
    isFromCache: true,
    isStale: !entry.isFresh(),
    cachedAt: entry.storedAt,
  );

  bool _sameData(dynamic a, dynamic b) {
    try {
      return jsonEncode(a) == jsonEncode(b);
    } catch (_) {
      return false;
    }
  }

  Future<void> _invalidateAfter(ApiRequest request) async {
    final prefixes = request.invalidateCache;
    if (prefixes == null || !_cache.isInitialized) return;
    for (final prefix in prefixes) {
      await _cache.invalidate(prefix);
    }
  }

  // ---------------------------------------------------------------------------
  // RAW SEND (throws DioException / ApiException)
  // ---------------------------------------------------------------------------

  Future<ApiResponse<dynamic>> _send(ApiRequest request) async {
    switch (request.requestType) {
      case RequestType.normal:
        return ResponseHandler.handle(await _normalRequest(request));

      case RequestType.upload:
        return ResponseHandler.handle(await _uploadRequest(request));

      case RequestType.download:
        return _downloadRequest(request);
    }
  }

  // ---------------------------------------------------------------------------
  // NORMAL REQUEST
  // ---------------------------------------------------------------------------

  Future<ApiResponse<dynamic>> _normalRequest(ApiRequest request) async {
    late Response response;

    switch (request.method) {
      case ApiMethod.get:
        response = await _dio.get(
          request.endpoint,
          queryParameters: request.queryParameters,
          options: Options(headers: request.headers),
          cancelToken: request.cancelRequest?.cancelToken,
        );
        break;

      case ApiMethod.post:
        response = await _dio.post(
          request.endpoint,
          data: request.body,
          queryParameters: request.queryParameters,
          options: Options(headers: request.headers),
          cancelToken: request.cancelRequest?.cancelToken,
        );
        break;

      case ApiMethod.put:
        response = await _dio.put(
          request.endpoint,
          data: request.body,
          queryParameters: request.queryParameters,
          options: Options(headers: request.headers),
          cancelToken: request.cancelRequest?.cancelToken,
        );
        break;

      case ApiMethod.patch:
        response = await _dio.patch(
          request.endpoint,
          data: request.body,
          queryParameters: request.queryParameters,
          options: Options(headers: request.headers),
          cancelToken: request.cancelRequest?.cancelToken,
        );
        break;

      case ApiMethod.delete:
        response = await _dio.delete(
          request.endpoint,
          data: request.body,
          queryParameters: request.queryParameters,
          options: Options(headers: request.headers),
          cancelToken: request.cancelRequest?.cancelToken,
        );
        break;
    }

    return ApiResponse(
      success: true,
      data: response.data,
      statusCode: response.statusCode,
    );
  }

  // ---------------------------------------------------------------------------
  // UPLOAD REQUEST
  // ---------------------------------------------------------------------------

  Future<ApiResponse<dynamic>> _uploadRequest(ApiRequest request) async {
    final formDataMap = <String, dynamic>{...?request.body};

    // Single File
    if (request.filePath != null) {
      formDataMap[request.fileField] = await MultipartFile.fromFile(
        request.filePath!,
        filename: request.filePath!.split('/').last,
      );
    }

    // Multiple Files
    if (request.files != null) {
      formDataMap[request.fileField] = await Future.wait(
        request.files!.map(
          (file) async => MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _dio.post(
      request.endpoint,
      data: formData,
      options: Options(headers: request.headers),
      cancelToken: request.cancelRequest?.cancelToken,
      onSendProgress: (sent, total) {
        request.onUploadProgress?.call(
          UploadProgress(sent: sent, total: total),
        );
      },
    );

    return ApiResponse(
      success: true,
      data: response.data,
      statusCode: response.statusCode,
    );
  }

  // ---------------------------------------------------------------------------
  // DOWNLOAD REQUEST
  // ---------------------------------------------------------------------------

  Future<ApiResponse<dynamic>> _downloadRequest(ApiRequest request) async {
    if (request.downloadSavePath == null) {
      throw ApiException(message: 'downloadSavePath is required');
    }

    await _dio.download(
      request.endpoint,
      request.downloadSavePath!,
      cancelToken: request.cancelRequest?.cancelToken,
      onReceiveProgress: (received, total) {
        request.onDownloadProgress?.call(
          DownloadProgress(received: received, total: total),
        );
      },
    );

    return ApiResponse(success: true, data: request.downloadSavePath);
  }
}
