import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_registry.dart';

/// Thin wrapper over `permission_handler` and the device info plugin.
/// Swap it in tests with [AppPermissionManager.debugSetBackend].
class PermissionBackend {
  const PermissionBackend();

  PermissionPlatform get platform {
    if (kIsWeb) return PermissionPlatform.other;
    if (Platform.isAndroid) return PermissionPlatform.android;
    if (Platform.isIOS) return PermissionPlatform.ios;
    return PermissionPlatform.other;
  }

  Future<int> androidSdkInt() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Future<PermissionStatus> status(Permission permission) => permission.status;

  Future<Map<Permission, PermissionStatus>> request(
    List<Permission> permissions,
  ) => permissions.request();

  Future<bool> shouldShowRationale(Permission permission) =>
      permission.shouldShowRequestRationale;

  Future<bool> openSettings() => openAppSettings();
}
