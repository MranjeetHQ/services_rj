import 'package:permission_handler/permission_handler.dart';

/// Result of checking or requesting an [AppPermission].
enum AppPermissionStatus {
  /// Full access.
  granted,

  /// Partial access, for example "selected photos only". The feature can
  /// be used with the subset the user picked.
  limited,

  /// Provisional access, for example quiet iOS notifications.
  provisional,

  /// Not granted. It can be requested again. On Android this is also the
  /// status before the first request.
  denied,

  /// Denied with "don't ask again", or denied once on iOS. Only the system
  /// settings screen can change it.
  permanentlyDenied,

  /// Blocked by the OS, parental controls or device policy. The user
  /// cannot change it.
  restricted,

  /// No runtime permission is needed on this platform or OS version, so the
  /// feature can be used directly.
  notApplicable;

  /// Whether the feature guarded by this permission can be used.
  bool get isUsable =>
      this == granted ||
      this == limited ||
      this == provisional ||
      this == notApplicable;

  /// Whether the only way forward is the system settings screen.
  bool get needsSettings => this == permanentlyDenied;

  /// Whether requesting again can show the system dialog.
  bool get canRequest => this == denied;

  /// Order used to combine several native statuses: the most blocking wins.
  int get _severity => switch (this) {
    permanentlyDenied => 6,
    restricted => 5,
    denied => 4,
    limited => 3,
    provisional => 2,
    granted => 1,
    notApplicable => 0,
  };

  static AppPermissionStatus fromNative(PermissionStatus status) =>
      switch (status) {
        PermissionStatus.granted => granted,
        PermissionStatus.limited => limited,
        PermissionStatus.provisional => provisional,
        PermissionStatus.denied => denied,
        PermissionStatus.permanentlyDenied => permanentlyDenied,
        PermissionStatus.restricted => restricted,
      };

  /// Combines the statuses of several native permissions behind one tag.
  static AppPermissionStatus combine(Iterable<AppPermissionStatus> statuses) {
    var result = notApplicable;
    for (final s in statuses) {
      if (s._severity > result._severity) result = s;
    }
    return result;
  }
}
