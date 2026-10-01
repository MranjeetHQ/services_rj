import 'package:permission_handler/permission_handler.dart';

import 'app_permission.dart';

/// Target platforms the permission layer understands.
enum PermissionPlatform { android, ios, other }

/// One `<uses-permission>` line for AndroidManifest.xml.
class AndroidManifestEntry {
  const AndroidManifestEntry(this.name, {this.maxSdkVersion, this.note});

  /// Full permission name, for example `android.permission.CAMERA`.
  final String name;

  /// Adds `android:maxSdkVersion` so the permission is only requested on
  /// older Android versions.
  final int? maxSdkVersion;

  final String? note;

  String toXml() {
    final max = maxSdkVersion == null
        ? ''
        : ' android:maxSdkVersion="$maxSdkVersion"';
    return '<uses-permission android:name="$name"$max />';
  }
}

/// Everything needed to use one [AppPermission] on both platforms.
class PermissionSpec {
  const PermissionSpec({
    required this.permission,
    required this.description,
    required this.android,
    required this.ios,
    this.androidManifest = const [],
    this.iosPlistKeys = const [],
    this.iosPodMacros = const [],
    this.sequential = false,
    this.notes = const [],
  });

  final AppPermission permission;

  final String description;

  /// Native permissions to use on Android for the given SDK level.
  /// An empty list means no runtime permission is needed.
  final List<Permission> Function(int sdkInt) android;

  /// Native permissions to use on iOS. Empty means not applicable.
  final List<Permission> ios;

  final List<AndroidManifestEntry> androidManifest;

  /// Info.plist keys. Each needs a user-facing reason string.
  final List<String> iosPlistKeys;

  /// Macros for the Podfile `GCC_PREPROCESSOR_DEFINITIONS` (CocoaPods builds).
  final List<String> iosPodMacros;

  /// Request the native permissions one after another, stopping at the
  /// first refusal. Needed when a permission depends on the previous one,
  /// such as background location.
  final bool sequential;

  final List<String> notes;

  bool get supportsAndroid => androidManifest.isNotEmpty;

  bool get supportsIos => ios.isNotEmpty;
}

/// Single source of truth for how each [AppPermission] maps to native
/// permissions, manifest entries and Info.plist keys.
///
/// `docs/permissions.md` is generated from this file, and a test fails if
/// the two drift apart.
abstract final class PermissionRegistry {
  // Android API levels used below.
  static const int android10 = 29;
  static const int android12 = 31;
  static const int android13 = 33;

  static const _legacyRead = AndroidManifestEntry(
    'android.permission.READ_EXTERNAL_STORAGE',
    maxSdkVersion: 32,
    note: 'Android 12 and lower',
  );

  static const _partialMedia = AndroidManifestEntry(
    'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
    note: 'Android 14+ "select photos" access, reported as limited',
  );

  static final Map<AppPermission, PermissionSpec> specs = {
    for (final spec in _all) spec.permission: spec,
  };

  static PermissionSpec of(AppPermission permission) => specs[permission]!;

  /// Native permissions for [permission] on [platform]. Empty when no
  /// runtime permission is needed.
  static List<Permission> resolve(
    AppPermission permission,
    PermissionPlatform platform, {
    int androidSdkInt = 0,
  }) {
    final spec = of(permission);
    return switch (platform) {
      PermissionPlatform.android => spec.android(androidSdkInt),
      PermissionPlatform.ios => spec.ios,
      PermissionPlatform.other => const [],
    };
  }

  static final List<PermissionSpec> _all = [
    PermissionSpec(
      permission: AppPermission.camera,
      description: 'Take photos and record video',
      android: (_) => [Permission.camera],
      ios: [Permission.camera],
      androidManifest: const [
        AndroidManifestEntry('android.permission.CAMERA'),
      ],
      iosPlistKeys: const ['NSCameraUsageDescription'],
      iosPodMacros: const ['PERMISSION_CAMERA'],
    ),
    PermissionSpec(
      permission: AppPermission.microphone,
      description: 'Record audio',
      android: (_) => [Permission.microphone],
      ios: [Permission.microphone],
      androidManifest: const [
        AndroidManifestEntry('android.permission.RECORD_AUDIO'),
      ],
      iosPlistKeys: const ['NSMicrophoneUsageDescription'],
      iosPodMacros: const ['PERMISSION_MICROPHONE'],
    ),
    PermissionSpec(
      permission: AppPermission.photos,
      description: 'Read images from the gallery',
      android: (sdk) =>
          sdk >= android13 ? [Permission.photos] : [Permission.storage],
      ios: [Permission.photos],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.READ_MEDIA_IMAGES',
          note: 'Android 13+',
        ),
        _partialMedia,
        _legacyRead,
      ],
      iosPlistKeys: const ['NSPhotoLibraryUsageDescription'],
      iosPodMacros: const ['PERMISSION_PHOTOS'],
      notes: const ['Android 12 and lower use READ_EXTERNAL_STORAGE.'],
    ),
    PermissionSpec(
      permission: AppPermission.videos,
      description: 'Read videos from the gallery',
      android: (sdk) =>
          sdk >= android13 ? [Permission.videos] : [Permission.storage],
      ios: [Permission.photos],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.READ_MEDIA_VIDEO',
          note: 'Android 13+',
        ),
        _partialMedia,
        _legacyRead,
      ],
      iosPlistKeys: const ['NSPhotoLibraryUsageDescription'],
      iosPodMacros: const ['PERMISSION_PHOTOS'],
      notes: const [
        'iOS has one photo library permission for images and videos.',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.audio,
      description: 'Read audio files or the music library',
      android: (sdk) =>
          sdk >= android13 ? [Permission.audio] : [Permission.storage],
      ios: [Permission.mediaLibrary],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.READ_MEDIA_AUDIO',
          note: 'Android 13+',
        ),
        _legacyRead,
      ],
      iosPlistKeys: const ['NSAppleMusicUsageDescription'],
      iosPodMacros: const ['PERMISSION_MEDIA_LIBRARY'],
    ),
    PermissionSpec(
      permission: AppPermission.storage,
      description: 'Legacy shared storage',
      android: (sdk) => sdk >= android13 ? const [] : [Permission.storage],
      ios: const [],
      androidManifest: const [
        _legacyRead,
        AndroidManifestEntry(
          'android.permission.WRITE_EXTERNAL_STORAGE',
          maxSdkVersion: 29,
          note: 'Android 10 and lower',
        ),
      ],
      notes: const [
        'Not applicable on Android 13+: use photos, videos or audio, or the system file picker.',
        'Not applicable on iOS: apps use their own sandbox.',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.location,
      description: 'Location while the app is in use',
      android: (_) => [Permission.locationWhenInUse],
      ios: [Permission.locationWhenInUse],
      androidManifest: const [
        AndroidManifestEntry('android.permission.ACCESS_FINE_LOCATION'),
        AndroidManifestEntry('android.permission.ACCESS_COARSE_LOCATION'),
      ],
      iosPlistKeys: const ['NSLocationWhenInUseUsageDescription'],
      iosPodMacros: const ['PERMISSION_LOCATION_WHENINUSE'],
      notes: const ['Android 12+ users may grant approximate location only.'],
    ),
    PermissionSpec(
      permission: AppPermission.locationAlways,
      description: 'Location in the background',
      android: (_) => [Permission.locationWhenInUse, Permission.locationAlways],
      ios: [Permission.locationWhenInUse, Permission.locationAlways],
      sequential: true,
      androidManifest: const [
        AndroidManifestEntry('android.permission.ACCESS_FINE_LOCATION'),
        AndroidManifestEntry('android.permission.ACCESS_COARSE_LOCATION'),
        AndroidManifestEntry(
          'android.permission.ACCESS_BACKGROUND_LOCATION',
          note: 'Android 10+',
        ),
      ],
      iosPlistKeys: const [
        'NSLocationWhenInUseUsageDescription',
        'NSLocationAlwaysAndWhenInUseUsageDescription',
      ],
      iosPodMacros: const ['PERMISSION_LOCATION'],
      notes: const [
        'Foreground location is requested first; both platforms require it.',
        'Android 11+ sends the user to settings for "Allow all the time".',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.notification,
      description: 'Show notifications',
      android: (sdk) => sdk >= android13 ? [Permission.notification] : const [],
      ios: [Permission.notification],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.POST_NOTIFICATIONS',
          note: 'Android 13+',
        ),
      ],
      iosPodMacros: const ['PERMISSION_NOTIFICATIONS'],
      notes: const [
        'No Info.plist key is needed.',
        'Granted automatically on Android 12 and lower.',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.contacts,
      description: 'Read and write contacts',
      android: (_) => [Permission.contacts],
      ios: [Permission.contacts],
      androidManifest: const [
        AndroidManifestEntry('android.permission.READ_CONTACTS'),
        AndroidManifestEntry('android.permission.WRITE_CONTACTS'),
      ],
      iosPlistKeys: const ['NSContactsUsageDescription'],
      iosPodMacros: const ['PERMISSION_CONTACTS'],
    ),
    PermissionSpec(
      permission: AppPermission.calendar,
      description: 'Read and write calendar events',
      android: (_) => [Permission.calendarFullAccess],
      ios: [Permission.calendarFullAccess],
      androidManifest: const [
        AndroidManifestEntry('android.permission.READ_CALENDAR'),
        AndroidManifestEntry('android.permission.WRITE_CALENDAR'),
      ],
      iosPlistKeys: const [
        'NSCalendarsFullAccessUsageDescription',
        'NSCalendarsUsageDescription',
      ],
      iosPodMacros: const [
        'PERMISSION_EVENTS_FULL_ACCESS',
        'PERMISSION_EVENTS',
      ],
      notes: const ['NSCalendarsUsageDescription covers iOS 16 and lower.'],
    ),
    PermissionSpec(
      permission: AppPermission.bluetooth,
      description: 'Scan for and connect to Bluetooth devices',
      android: (sdk) => sdk >= android12
          ? [Permission.bluetoothScan, Permission.bluetoothConnect]
          : [Permission.locationWhenInUse],
      ios: [Permission.bluetooth],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.BLUETOOTH_SCAN',
          note: 'Android 12+',
        ),
        AndroidManifestEntry(
          'android.permission.BLUETOOTH_CONNECT',
          note: 'Android 12+',
        ),
        AndroidManifestEntry('android.permission.BLUETOOTH', maxSdkVersion: 30),
        AndroidManifestEntry(
          'android.permission.BLUETOOTH_ADMIN',
          maxSdkVersion: 30,
        ),
        AndroidManifestEntry(
          'android.permission.ACCESS_FINE_LOCATION',
          maxSdkVersion: 30,
          note: 'BLE scanning on Android 11 and lower',
        ),
      ],
      iosPlistKeys: const ['NSBluetoothAlwaysUsageDescription'],
      iosPodMacros: const ['PERMISSION_BLUETOOTH'],
      notes: const [
        'Android 11 and lower need location permission to find BLE devices.',
        'If you also use AppPermission.location, drop maxSdkVersion from ACCESS_FINE_LOCATION.',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.motion,
      description: 'Physical activity and motion data',
      android: (sdk) =>
          sdk >= android10 ? [Permission.activityRecognition] : const [],
      ios: [Permission.sensors],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.ACTIVITY_RECOGNITION',
          note: 'Android 10+',
        ),
      ],
      iosPlistKeys: const ['NSMotionUsageDescription'],
      iosPodMacros: const ['PERMISSION_SENSORS'],
    ),
    PermissionSpec(
      permission: AppPermission.bodySensors,
      description: 'Body sensors such as heart rate',
      android: (_) => [Permission.sensors],
      ios: const [],
      androidManifest: const [
        AndroidManifestEntry('android.permission.BODY_SENSORS'),
      ],
      notes: const [
        'Not applicable on iOS: health data goes through HealthKit.',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.speech,
      description: 'Speech-to-text',
      android: (_) => [Permission.microphone],
      ios: [Permission.speech, Permission.microphone],
      androidManifest: const [
        AndroidManifestEntry('android.permission.RECORD_AUDIO'),
      ],
      iosPlistKeys: const [
        'NSSpeechRecognitionUsageDescription',
        'NSMicrophoneUsageDescription',
      ],
      iosPodMacros: const [
        'PERMISSION_SPEECH_RECOGNIZER',
        'PERMISSION_MICROPHONE',
      ],
      notes: const [
        'Android only needs the microphone; iOS also needs speech recognition.',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.phone,
      description: 'Phone state and calls',
      android: (_) => [Permission.phone],
      ios: const [],
      androidManifest: const [
        AndroidManifestEntry('android.permission.READ_PHONE_STATE'),
        AndroidManifestEntry('android.permission.CALL_PHONE'),
      ],
      notes: const ['Not applicable on iOS.'],
    ),
    PermissionSpec(
      permission: AppPermission.sms,
      description: 'Send and read SMS',
      android: (_) => [Permission.sms],
      ios: const [],
      androidManifest: const [
        AndroidManifestEntry('android.permission.SEND_SMS'),
        AndroidManifestEntry('android.permission.READ_SMS'),
        AndroidManifestEntry('android.permission.RECEIVE_SMS'),
      ],
      notes: const [
        'Not applicable on iOS. Google Play restricts SMS permissions.',
      ],
    ),
    PermissionSpec(
      permission: AppPermission.appTracking,
      description: 'App Tracking Transparency',
      android: (_) => const [],
      ios: [Permission.appTrackingTransparency],
      iosPlistKeys: const ['NSUserTrackingUsageDescription'],
      iosPodMacros: const ['PERMISSION_APP_TRACKING_TRANSPARENCY'],
      notes: const ['Not applicable on Android.'],
    ),
    PermissionSpec(
      permission: AppPermission.exactAlarm,
      description: 'Schedule exact alarms',
      android: (sdk) =>
          sdk >= android12 ? [Permission.scheduleExactAlarm] : const [],
      ios: const [],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.SCHEDULE_EXACT_ALARM',
          note: 'Android 12+',
        ),
      ],
      notes: const ['Opens a system settings page instead of a dialog.'],
    ),
    PermissionSpec(
      permission: AppPermission.batteryOptimization,
      description: 'Exclude the app from battery optimization',
      android: (_) => [Permission.ignoreBatteryOptimizations],
      ios: const [],
      androidManifest: const [
        AndroidManifestEntry(
          'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        ),
      ],
      notes: const ['Google Play only allows this for specific app types.'],
    ),
    PermissionSpec(
      permission: AppPermission.reminders,
      description: 'Read and write reminders',
      android: (_) => const [],
      ios: [Permission.reminders],
      iosPlistKeys: const [
        'NSRemindersFullAccessUsageDescription',
        'NSRemindersUsageDescription',
      ],
      iosPodMacros: const ['PERMISSION_REMINDERS'],
      notes: const ['Not applicable on Android.'],
    ),
  ];
}
