import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:permission_handler/permission_handler.dart';
import 'package:services_rj/services_rj.dart';

/// Marks the camera as granted, as if the user did it in system settings.
void grantCamera(FakeBackend backend) =>
    backend.statuses[Permission.camera] = PermissionStatus.granted;

/// Scriptable stand-in for the permission plugins.
class FakeBackend extends PermissionBackend {
  /// Creates a backend that behaves like Android 14.
  FakeBackend({this.os = PermissionPlatform.android, this.sdk = 34});

  /// Reported platform.
  PermissionPlatform os;

  /// Reported Android SDK level.
  int sdk;

  /// Current status per native permission. Missing means denied.
  final Map<Permission, PermissionStatus> statuses = {};

  /// What a request returns. Missing means granted.
  final Map<Permission, PermissionStatus> requestResults = {};

  /// Requests received.
  final List<List<Permission>> requested = [];

  @override
  PermissionPlatform get platform => os;

  @override
  Future<int> androidSdkInt() async => sdk;

  @override
  Future<PermissionStatus> status(Permission p) async =>
      statuses[p] ?? PermissionStatus.denied;

  @override
  Future<Map<Permission, PermissionStatus>> request(List<Permission> ps) async {
    requested.add(ps);
    return {
      for (final p in ps)
        p: statuses[p] = requestResults[p] ?? PermissionStatus.granted,
    };
  }

  @override
  Future<bool> shouldShowRationale(Permission p) async => false;

  @override
  Future<bool> openSettings() async => false;
}

/// Starts a loopback server that mimics the endpoints the demos call.
///
/// [next] supplies a number that changes on every GET so revalidation can
/// tell old data from new.
Future<HttpServer> startLocalServer(int Function() next) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    final path = req.uri.path;
    final response = req.response;
    Future<void> json(Object body, [int status = 200]) async {
      response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await response.close();
    }

    try {
      if (path == '/headers') {
        final headers = <String, String>{};
        req.headers.forEach((name, values) => headers[name] = values.join(','));
        await json({'headers': headers});
      } else if (path == '/slow') {
        await Future<void>.delayed(const Duration(seconds: 2));
        await json({'slow': true});
      } else if (path == '/upload') {
        final bytes = await req.fold<int>(0, (n, chunk) => n + chunk.length);
        await json({'parts': bytes});
      } else if (path == '/bytes') {
        response
          ..headers.contentLength = 20000
          ..add(List<int>.filled(20000, 7));
        await response.close();
      } else if (path.startsWith('/status/')) {
        await json({'message': 'status'}, int.parse(path.split('/').last));
      } else if (path == '/posts/99999') {
        await json({'message': 'not found'}, 404);
      } else if (req.method == 'POST') {
        await req.drain<void>();
        await json({'id': 101}, 201);
      } else {
        await json({'path': path, 'n': next()});
      }
    } catch (_) {
      // The client went away (cancelled or timed out).
    }
  });
  return server;
}
