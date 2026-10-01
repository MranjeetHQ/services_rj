/// App-level permission tags.
///
/// Apps always use these tags. Each tag is resolved to the right
/// `permission_handler` permissions for the current platform and OS version
/// by [PermissionRegistry], so one tag can mean different native
/// permissions on Android and iOS.
///
/// When you add a tag here, also add its mapping in
/// `permission_registry.dart` and regenerate `docs/permissions.md`
/// (see the "Adding a new permission" section of that file).
enum AppPermission {
  /// Take photos and record video.
  camera,

  /// Record audio.
  microphone,

  /// Read images from the gallery.
  photos,

  /// Read videos from the gallery.
  videos,

  /// Read audio files or the music library.
  audio,

  /// Legacy shared storage (Android 12 and lower only).
  storage,

  /// Location while the app is in use.
  location,

  /// Location in the background. Requests foreground location first.
  locationAlways,

  /// Show notifications.
  notification,

  /// Read and write contacts.
  contacts,

  /// Read and write calendar events.
  calendar,

  /// Scan for and connect to Bluetooth devices.
  bluetooth,

  /// Physical activity and motion data.
  motion,

  /// Body sensors such as heart rate (Android only).
  bodySensors,

  /// Speech-to-text.
  speech,

  /// Phone state and calls (Android only).
  phone,

  /// Send and read SMS (Android only).
  sms,

  /// App Tracking Transparency (iOS only).
  appTracking,

  /// Schedule exact alarms (Android 12 and higher only).
  exactAlarm,

  /// Ask to be excluded from battery optimization (Android only).
  batteryOptimization,

  /// Read and write reminders (iOS only).
  reminders,
}
