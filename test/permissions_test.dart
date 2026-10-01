import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:services_rj/services_rj.dart';

/// Scriptable stand-in for the platform plugins.
class FakeBackend extends PermissionBackend {
  FakeBackend({this.os = PermissionPlatform.android, this.sdk = 34});

  PermissionPlatform os;
  int sdk;

  final Map<Permission, PermissionStatus> statuses = {};
  final Map<Permission, PermissionStatus> requestResults = {};
  final Set<Permission> rationale = {};
  final List<List<Permission>> requested = [];
  int settingsOpened = 0;
  int concurrent = 0;
  int maxConcurrent = 0;
  Duration requestDelay = Duration.zero;
  bool throwOnRequest = false;

  @override
  PermissionPlatform get platform => os;

  @override
  Future<int> androidSdkInt() async => sdk;

  @override
  Future<PermissionStatus> status(Permission p) async =>
      statuses[p] ?? PermissionStatus.denied;

  @override
  Future<Map<Permission, PermissionStatus>> request(List<Permission> ps) async {
    concurrent++;
    maxConcurrent = concurrent > maxConcurrent ? concurrent : maxConcurrent;
    try {
      requested.add(ps);
      await Future<void>.delayed(requestDelay);
      if (throwOnRequest) throw Exception('No permissions found in manifest');
      return {
        for (final p in ps)
          p: statuses[p] = requestResults[p] ?? PermissionStatus.granted,
      };
    } finally {
      concurrent--;
    }
  }

  @override
  Future<bool> shouldShowRationale(Permission p) async => rationale.contains(p);

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return false; // Skip waiting for a lifecycle resume in tests.
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manager = AppPermissionManager.instance;
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    manager
      ..debugSetBackend(backend)
      ..enabled = true;
  });

  group('registry', () {
    test('every tag has a spec', () {
      for (final p in AppPermission.values) {
        expect(PermissionRegistry.specs.containsKey(p), isTrue, reason: p.name);
      }
    });

    test('every tag is usable on at least one platform', () {
      for (final spec in PermissionRegistry.specs.values) {
        final onAndroid = [
          21,
          29,
          31,
          33,
          35,
        ].any((sdk) => spec.android(sdk).isNotEmpty);
        expect(
          onAndroid || spec.ios.isNotEmpty,
          isTrue,
          reason: spec.permission.name,
        );
      }
    });

    test('native mappings always come with the matching setup entries', () {
      for (final spec in PermissionRegistry.specs.values) {
        final name = spec.permission.name;
        final usedOnAndroid = [
          21,
          29,
          31,
          33,
          35,
        ].any((sdk) => spec.android(sdk).isNotEmpty);
        if (usedOnAndroid) {
          expect(
            spec.androidManifest,
            isNotEmpty,
            reason: '$name needs manifest entries',
          );
        }
        if (spec.ios.isNotEmpty) {
          expect(
            spec.iosPodMacros,
            isNotEmpty,
            reason: '$name needs a Podfile macro',
          );
          if (spec.permission != AppPermission.notification) {
            expect(
              spec.iosPlistKeys,
              isNotEmpty,
              reason: '$name needs an Info.plist key',
            );
          }
        }
      }
    });

    test('media tags switch native permission at Android 13', () {
      for (final tag in [
        AppPermission.photos,
        AppPermission.videos,
        AppPermission.audio,
      ]) {
        expect(
          PermissionRegistry.resolve(
            tag,
            PermissionPlatform.android,
            androidSdkInt: 32,
          ),
          [Permission.storage],
        );
      }
      expect(
        PermissionRegistry.resolve(
          AppPermission.photos,
          PermissionPlatform.android,
          androidSdkInt: 33,
        ),
        [Permission.photos],
      );
      expect(
        PermissionRegistry.resolve(
          AppPermission.storage,
          PermissionPlatform.android,
          androidSdkInt: 33,
        ),
        isEmpty,
      );
    });

    test('same tag maps to different natives on Android and iOS', () {
      expect(
        PermissionRegistry.resolve(
          AppPermission.motion,
          PermissionPlatform.android,
          androidSdkInt: 34,
        ),
        [Permission.activityRecognition],
      );
      expect(
        PermissionRegistry.resolve(
          AppPermission.motion,
          PermissionPlatform.ios,
        ),
        [Permission.sensors],
      );
      expect(
        PermissionRegistry.resolve(
          AppPermission.bluetooth,
          PermissionPlatform.android,
          androidSdkInt: 31,
        ),
        [Permission.bluetoothScan, Permission.bluetoothConnect],
      );
      expect(
        PermissionRegistry.resolve(
          AppPermission.bluetooth,
          PermissionPlatform.android,
          androidSdkInt: 30,
        ),
        [Permission.locationWhenInUse],
      );
      expect(
        PermissionRegistry.resolve(
          AppPermission.bluetooth,
          PermissionPlatform.ios,
        ),
        [Permission.bluetooth],
      );
    });

    test('unsupported platforms resolve to nothing', () {
      for (final p in AppPermission.values) {
        expect(
          PermissionRegistry.resolve(p, PermissionPlatform.other),
          isEmpty,
        );
      }
    });
  });

  group('status', () {
    test('most blocking status wins', () {
      expect(
        AppPermissionStatus.combine([
          AppPermissionStatus.granted,
          AppPermissionStatus.limited,
        ]),
        AppPermissionStatus.limited,
      );
      expect(
        AppPermissionStatus.combine([
          AppPermissionStatus.granted,
          AppPermissionStatus.permanentlyDenied,
          AppPermissionStatus.denied,
        ]),
        AppPermissionStatus.permanentlyDenied,
      );
      expect(
        AppPermissionStatus.combine([]),
        AppPermissionStatus.notApplicable,
      );
    });

    test('usable statuses', () {
      expect(AppPermissionStatus.values.where((s) => s.isUsable).toSet(), {
        AppPermissionStatus.granted,
        AppPermissionStatus.limited,
        AppPermissionStatus.provisional,
        AppPermissionStatus.notApplicable,
      });
    });
  });

  group('manager', () {
    test('uses the SDK level to pick natives', () async {
      backend.sdk = 30;
      await manager.request(AppPermission.photos);
      expect(backend.requested.single, [Permission.storage]);
    });

    test('not applicable tags never touch the plugin', () async {
      backend.sdk = 31;
      expect(
        await manager.request(AppPermission.notification),
        AppPermissionStatus.notApplicable,
      );
      backend.os = PermissionPlatform.ios;
      expect(
        await manager.request(AppPermission.sms),
        AppPermissionStatus.notApplicable,
      );
      expect(backend.requested, isEmpty);
    });

    test('concurrent requests are serialized', () async {
      backend.requestDelay = const Duration(milliseconds: 20);
      await Future.wait([
        manager.request(AppPermission.camera),
        manager.request(AppPermission.microphone),
        manager.ensure(AppPermission.contacts),
        manager.requestAll([AppPermission.location, AppPermission.calendar]),
      ]);
      expect(backend.maxConcurrent, 1);
      expect(backend.requested.length, 5);
    });

    test('a failing request does not block the queue', () async {
      backend.throwOnRequest = true;
      expect(
        await manager.request(AppPermission.camera),
        AppPermissionStatus.denied,
      );
      backend.throwOnRequest = false;
      expect(
        await manager.request(AppPermission.camera),
        AppPermissionStatus.granted,
      );
    });

    test(
      'background location asks foreground first and stops on refusal',
      () async {
        backend.requestResults[Permission.locationWhenInUse] =
            PermissionStatus.denied;
        expect(
          await manager.request(AppPermission.locationAlways),
          AppPermissionStatus.denied,
        );
        expect(backend.requested, [
          [Permission.locationWhenInUse],
        ]);

        backend.requested.clear();
        backend.requestResults[Permission.locationWhenInUse] =
            PermissionStatus.granted;
        expect(
          await manager.request(AppPermission.locationAlways),
          AppPermissionStatus.granted,
        );
        expect(backend.requested, [
          [Permission.locationWhenInUse],
          [Permission.locationAlways],
        ]);
      },
    );

    test('multi-native tags are requested together', () async {
      backend.requestResults[Permission.bluetoothConnect] =
          PermissionStatus.denied;
      expect(
        await manager.request(AppPermission.bluetooth),
        AppPermissionStatus.denied,
      );
      expect(backend.requested.single, [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ]);
    });

    test('disabled feature throws', () {
      manager.enabled = false;
      expect(() => manager.check(AppPermission.camera), throwsStateError);
    });
  });

  group('ensure', () {
    test('returns at once when granted', () async {
      backend.statuses[Permission.camera] = PermissionStatus.granted;
      expect(
        await manager.ensure(AppPermission.camera),
        AppPermissionStatus.granted,
      );
      expect(backend.requested, isEmpty);
    });

    test('restricted is never requested', () async {
      backend.statuses[Permission.camera] = PermissionStatus.restricted;
      expect(
        await manager.ensure(AppPermission.camera),
        AppPermissionStatus.restricted,
      );
      expect(backend.requested, isEmpty);
    });

    test('declined rationale skips the request', () async {
      backend.rationale.add(Permission.camera);
      final status = await manager.ensure(
        AppPermission.camera,
        prompts: PermissionPrompts(onRationale: (_) async => false),
      );
      expect(status, AppPermissionStatus.denied);
      expect(backend.requested, isEmpty);
    });

    test('accepted rationale requests', () async {
      backend.rationale.add(Permission.camera);
      var asked = 0;
      final status = await manager.ensure(
        AppPermission.camera,
        prompts: PermissionPrompts(
          onRationale: (_) async {
            asked++;
            return true;
          },
        ),
      );
      expect(asked, 1);
      expect(status, AppPermissionStatus.granted);
    });

    test('iOS permanent denial offers settings without requesting', () async {
      backend.os = PermissionPlatform.ios;
      backend.statuses[Permission.camera] = PermissionStatus.permanentlyDenied;
      await manager.ensure(
        AppPermission.camera,
        prompts: PermissionPrompts(onOpenSettings: (_) async => true),
      );
      expect(backend.requested, isEmpty);
      expect(backend.settingsOpened, 1);
    });

    test('Android silent "don\'t ask again" offers settings', () async {
      // check() says denied, request returns permanentlyDenied without a dialog.
      backend.requestResults[Permission.camera] =
          PermissionStatus.permanentlyDenied;
      await manager.ensure(
        AppPermission.camera,
        prompts: PermissionPrompts(onOpenSettings: (_) async => true),
      );
      expect(backend.settingsOpened, 1);
    });

    test(
      'Android second denial after a rationale does not nag with settings',
      () async {
        backend.rationale.add(Permission.camera);
        backend.requestResults[Permission.camera] =
            PermissionStatus.permanentlyDenied;
        final status = await manager.ensure(
          AppPermission.camera,
          prompts: PermissionPrompts(
            onRationale: (_) async => true,
            onOpenSettings: (_) async => true,
          ),
        );
        expect(status, AppPermissionStatus.permanentlyDenied);
        expect(backend.settingsOpened, 0);
      },
    );
  });

  group('setup snippets', () {
    test('manifest merges duplicates and keeps the broader entry', () {
      final xml = PermissionSetup.androidManifest([
        AppPermission.bluetooth,
        AppPermission.location,
      ]);
      final fine = RegExp('ACCESS_FINE_LOCATION').allMatches(xml).length;
      expect(fine, 1);
      expect(
        xml,
        contains(
          '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
        ),
      );
    });

    test('plist and podfile list each key once', () {
      final plist = PermissionSetup.iosInfoPlist([
        AppPermission.photos,
        AppPermission.videos,
      ]);
      expect(
        RegExp('NSPhotoLibraryUsageDescription').allMatches(plist).length,
        1,
      );
      final pod = PermissionSetup.iosPodfile([
        AppPermission.speech,
        AppPermission.microphone,
      ]);
      expect(RegExp('PERMISSION_MICROPHONE').allMatches(pod).length, 1);
    });
  });

  test('docs/permissions.md reference table matches the registry', () {
    final file = File('docs/permissions.md');
    final doc = file.readAsStringSync();
    const begin = '<!-- PERMISSIONS:BEGIN -->';
    const end = '<!-- PERMISSIONS:END -->';
    final start = doc.indexOf(begin);
    final stop = doc.indexOf(end);
    expect(start, greaterThanOrEqualTo(0));
    expect(stop, greaterThan(start));

    final expected = '$begin\n${PermissionSetup.markdownReference()}\n$end';
    final actual = doc.substring(start, stop + end.length);

    if (Platform.environment['UPDATE_PERMISSION_DOCS'] == '1') {
      file.writeAsStringSync(
        doc.replaceRange(start, stop + end.length, expected),
      );
      return;
    }

    expect(
      actual,
      expected,
      reason:
          'docs/permissions.md is out of date. Run:\n'
          'UPDATE_PERMISSION_DOCS=1 flutter test test/permissions_test.dart',
    );
  });
}
