import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_logger.dart';
import 'app_permission.dart';
import 'app_permission_status.dart';
import 'permission_backend.dart';
import 'permission_registry.dart';

/// Asked before the system dialog when Android says the user should see an
/// explanation. Return `true` to continue with the request.
typedef PermissionRationaleCallback =
    Future<bool> Function(AppPermission permission);

/// Asked when the permission can only be changed in system settings.
/// Return `true` to open the settings screen.
typedef PermissionSettingsCallback =
    Future<bool> Function(AppPermission permission);

/// Checks and requests [AppPermission]s on Android and iOS.
///
/// * One tag maps to the right native permissions for the platform and OS
///   version, see [PermissionRegistry].
/// * Requests are queued, so two widgets asking at once never hit the
///   "a request is already running" error.
/// * [ensure] runs the whole flow: check, explain, request, and send the
///   user to settings when needed, then re-check on return.
///
/// ```dart
/// final status = await AppPermissionManager.instance.ensure(
///   AppPermission.camera,
///   prompts: PermissionPrompts.material(context),
/// );
/// if (status.isUsable) openCamera();
/// ```
class AppPermissionManager {
  AppPermissionManager._();

  static final AppPermissionManager instance = AppPermissionManager._();

  PermissionBackend _backend = const PermissionBackend();

  int? _sdkInt;

  Future<void> _queue = Future.value();

  /// Controlled by [AppController] through the `permissions` feature.
  bool enabled = true;

  /// How long to wait for the app to leave the foreground after opening
  /// settings. If it never leaves (split screen, settings failed to open),
  /// the flow continues instead of blocking every later request.
  Duration settingsLeaveTimeout = const Duration(seconds: 3);

  @visibleForTesting
  void debugSetBackend(PermissionBackend backend) {
    _backend = backend;
    _sdkInt = null;
    _queue = Future.value();
  }

  PermissionPlatform get platform => _backend.platform;

  /// Reads the Android SDK level ahead of time so the first check has no
  /// extra delay. Called by [AppController.initialize].
  Future<void> warmUp() async {
    if (platform == PermissionPlatform.android) await _androidSdk();
  }

  // ---------------------------------------------------------------------------
  // CHECK
  // ---------------------------------------------------------------------------

  /// Current status without showing any dialog.
  ///
  /// On Android a permission that was never requested and one denied with
  /// "don't ask again" both report [AppPermissionStatus.denied] until the
  /// next request. [request] and [ensure] report the precise status.
  Future<AppPermissionStatus> check(AppPermission permission) async {
    _requireEnabled();
    final natives = await nativePermissions(permission);
    if (natives.isEmpty) return AppPermissionStatus.notApplicable;

    final statuses = await Future.wait(natives.map(_backend.status));
    return AppPermissionStatus.combine(
      statuses.map(AppPermissionStatus.fromNative),
    );
  }

  Future<bool> isGranted(AppPermission permission) async =>
      (await check(permission)).isUsable;

  Future<Map<AppPermission, AppPermissionStatus>> checkAll(
    Iterable<AppPermission> permissions,
  ) async {
    final result = <AppPermission, AppPermissionStatus>{};
    for (final p in permissions.toSet()) {
      result[p] = await check(p);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // REQUEST
  // ---------------------------------------------------------------------------

  /// Shows the system dialog if needed and returns the result.
  Future<AppPermissionStatus> request(AppPermission permission) {
    _requireEnabled();
    return _serialized(() => _request(permission));
  }

  /// Requests several permissions one tag at a time.
  Future<Map<AppPermission, AppPermissionStatus>> requestAll(
    Iterable<AppPermission> permissions,
  ) {
    _requireEnabled();
    return _serialized(() async {
      final result = <AppPermission, AppPermissionStatus>{};
      for (final p in permissions.toSet()) {
        result[p] = await _request(p);
      }
      return result;
    });
  }

  /// Full flow for one permission:
  ///
  /// 1. Already usable: return right away.
  /// 2. Restricted: return, the user cannot change it.
  /// 3. Only settings can help: ask [prompts] and open settings, then
  ///    re-check when the app comes back.
  /// 4. Android wants an explanation: ask [prompts] before the dialog.
  /// 5. Request.
  ///
  /// Do not call [request] or [ensure] from inside a [prompts] callback:
  /// requests are queued, so the inner call would wait for this one forever.
  Future<AppPermissionStatus> ensure(
    AppPermission permission, {
    PermissionPrompts prompts = const PermissionPrompts(),
  }) {
    _requireEnabled();
    return _serialized(() async {
      var status = await check(permission);
      if (status.isUsable || status == AppPermissionStatus.restricted) {
        return status;
      }

      if (status.needsSettings) {
        return _viaSettings(permission, status, prompts);
      }

      final rationaleBefore = await _shouldShowRationale(permission);
      if (prompts.onRationale != null && rationaleBefore) {
        if (!await prompts.onRationale!(permission)) return status;
      }

      status = await _request(permission);

      // Android's check() reports "denied" even after "don't ask again", and
      // the request then returns permanentlyDenied without any dialog. No
      // rationale before plus permanentlyDenied after means no dialog was
      // shown, so offer settings instead of failing silently.
      if (status.needsSettings &&
          platform == PermissionPlatform.android &&
          !rationaleBefore) {
        return _viaSettings(permission, status, prompts);
      }
      return status;
    });
  }

  // ---------------------------------------------------------------------------
  // SETTINGS
  // ---------------------------------------------------------------------------

  Future<bool> openSettings() => _backend.openSettings();

  /// Opens the app's settings page and completes with the new status once
  /// the user comes back to the app, or after [timeout].
  Future<AppPermissionStatus> openSettingsAndWait(
    AppPermission permission, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    _requireEnabled();
    final waiter = _ResumeWaiter();
    try {
      final opened = await _backend.openSettings();
      if (opened) {
        final left = await waiter.left
            .then((_) => true)
            .timeout(settingsLeaveTimeout, onTimeout: () => false);
        if (left) await waiter.future.timeout(timeout, onTimeout: () {});
      }
    } finally {
      waiter.dispose();
    }
    return check(permission);
  }

  // ---------------------------------------------------------------------------
  // SETUP HELPERS
  // ---------------------------------------------------------------------------

  /// Native permissions behind [permission] on this device.
  Future<List<Permission>> nativePermissions(AppPermission permission) async {
    final p = platform;
    return PermissionRegistry.resolve(
      permission,
      p,
      androidSdkInt: p == PermissionPlatform.android ? await _androidSdk() : 0,
    );
  }

  // ---------------------------------------------------------------------------
  // PRIVATE
  // ---------------------------------------------------------------------------

  Future<AppPermissionStatus> _request(AppPermission permission) async {
    final natives = await nativePermissions(permission);
    if (natives.isEmpty) return AppPermissionStatus.notApplicable;

    try {
      if (PermissionRegistry.of(permission).sequential) {
        var last = AppPermissionStatus.notApplicable;
        for (final native in natives) {
          final result = await _backend.request([native]);
          last = AppPermissionStatus.fromNative(result[native]!);
          if (!last.isUsable) return last;
        }
        return last;
      }

      final result = await _backend.request(natives);
      return AppPermissionStatus.combine(
        natives.map((n) => AppPermissionStatus.fromNative(result[n]!)),
      );
    } catch (e, st) {
      // Missing manifest entry, missing Info.plist key or plugin error.
      AppLogger.error(
        'Permission request for ${permission.name} failed: $e. '
        'Check the setup in docs/permissions.md.',
        stackTrace: st,
      );
      return AppPermissionStatus.denied;
    }
  }

  Future<AppPermissionStatus> _viaSettings(
    AppPermission permission,
    AppPermissionStatus status,
    PermissionPrompts prompts,
  ) async {
    final ask = prompts.onOpenSettings;
    if (ask == null || !await ask(permission)) return status;
    return openSettingsAndWait(permission);
  }

  Future<bool> _shouldShowRationale(AppPermission permission) async {
    if (platform != PermissionPlatform.android) return false;
    for (final native in await nativePermissions(permission)) {
      if (await _backend.shouldShowRationale(native)) return true;
    }
    return false;
  }

  Future<int> _androidSdk() async {
    if (_sdkInt != null) return _sdkInt!;
    try {
      return _sdkInt = await _backend.androidSdkInt();
    } catch (e) {
      // Assume a current Android version rather than failing.
      AppLogger.warning('Could not read Android SDK level: $e');
      return _sdkInt = PermissionRegistry.android13;
    }
  }

  /// Runs [task] after every earlier request has finished. One failing task
  /// never blocks the ones after it.
  Future<T> _serialized<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  void _requireEnabled() {
    if (!enabled) {
      throw StateError('The permissions feature is disabled in AppFeatures.');
    }
  }
}

/// Optional UI hooks for [AppPermissionManager.ensure].
class PermissionPrompts {
  const PermissionPrompts({this.onRationale, this.onOpenSettings});

  /// Ready-made Material dialogs. Texts can be customized per permission.
  factory PermissionPrompts.material(
    BuildContext context, {
    String Function(AppPermission)? rationaleText,
    String Function(AppPermission)? settingsText,
    String title = 'Permission needed',
    String continueLabel = 'Continue',
    String settingsLabel = 'Open settings',
    String cancelLabel = 'Not now',
  }) {
    String label(AppPermission p) =>
        PermissionRegistry.of(p).description.toLowerCase();

    Future<bool> show(String message, String confirm) async {
      if (!context.mounted) return false;
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirm),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    return PermissionPrompts(
      onRationale: (p) => show(
        rationaleText?.call(p) ?? 'This app needs access to ${label(p)}.',
        continueLabel,
      ),
      onOpenSettings: (p) => show(
        settingsText?.call(p) ??
            'Access to ${label(p)} is turned off. You can turn it on in Settings.',
        settingsLabel,
      ),
    );
  }

  final PermissionRationaleCallback? onRationale;

  final PermissionSettingsCallback? onOpenSettings;
}

/// Completes on the first `resumed` that follows the app leaving the
/// foreground, which is when the user returns from the settings screen.
class _ResumeWaiter with WidgetsBindingObserver {
  _ResumeWaiter() {
    WidgetsBinding.instance.addObserver(this);
  }

  final Completer<void> _completer = Completer<void>();

  final Completer<void> _leftCompleter = Completer<void>();

  /// Completes when the app leaves the foreground.
  Future<void> get left => _leftCompleter.future;

  /// Completes when the app is back in the foreground.
  Future<void> get future => _completer.future;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_leftCompleter.isCompleted && !_completer.isCompleted) {
        _completer.complete();
      }
    } else if (!_leftCompleter.isCompleted) {
      _leftCompleter.complete();
    }
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
