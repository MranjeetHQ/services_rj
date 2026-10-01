# Permissions

`services_rj` wraps [`permission_handler`](https://pub.dev/packages/permission_handler) behind one app-level enum, `AppPermission`. Your code always asks for a tag such as `AppPermission.photos`. The package resolves the tag to the right native permission for the platform and OS version. For example, photos means `READ_MEDIA_IMAGES` on Android 13 and higher, `READ_EXTERNAL_STORAGE` on Android 12 and lower, and the photo library on iOS.

## Contents

- [Quick start](#quick-start)
- [Statuses](#statuses)
- [The ensure flow](#the-ensure-flow)
- [Platform setup](#platform-setup)
- [Permission reference](#permission-reference)
- [Adding a new permission](#adding-a-new-permission)
- [Known platform behaviour](#known-platform-behaviour)
- [Change log](#change-log)

## Quick start

The feature is on by default. `AppController.initialize()` also reads the Android SDK level once, so later checks have no extra delay.

```dart
await AppController.initialize(apiConfig: ApiConfig(baseUrl: '...'));

// Simple check and request
final status = await AppPermissionManager.instance.request(AppPermission.camera);
if (status.isUsable) openCamera();

// Full flow with explanation and settings dialogs
final result = await AppController.instance.permissions.ensure(
  AppPermission.location,
  prompts: PermissionPrompts.material(
    context,
    rationaleText: (_) => 'We use your location to show nearby stores.',
  ),
);

// Several at once
final map = await AppPermissionManager.instance.requestAll([
  AppPermission.camera,
  AppPermission.microphone,
]);
```

Turn the feature off with `AppFeatures(permissions: false)`. Every call then throws a `StateError`, which makes accidental use easy to spot.

## Statuses

| Status | Meaning | `isUsable` |
|---|---|---|
| `granted` | Full access. | yes |
| `limited` | Partial access, such as selected photos only. | yes |
| `provisional` | Quiet iOS notifications. | yes |
| `notApplicable` | No runtime permission exists on this platform or OS version. | yes |
| `denied` | Not granted, can be asked again. On Android this is also the status before the first request. | no |
| `permanentlyDenied` | Only the Settings app can change it. | no |
| `restricted` | Blocked by the OS or parental controls. The user cannot change it. | no |

When one tag maps to several native permissions, the most blocking status wins. Bluetooth on Android 12 is an example, since it needs both scan and connect.

## The ensure flow

`ensure()` runs this sequence and returns the final status:

1. The permission is already usable or restricted, so it returns at once.
2. The permission is permanently denied. `onOpenSettings` is asked, settings open, and the status is checked again when the user returns to the app.
3. Android says an explanation should be shown. `onRationale` is asked before the system dialog.
4. The system dialog is shown.
5. Android returned `permanentlyDenied` without showing a dialog, because the user chose "don't ask again" earlier. The flow continues as in step 2.

All requests go through one queue. Two widgets that ask at the same time never trigger permission_handler's "A request for permissions is already running" error.

> Do not call `request()` or `ensure()` from inside a prompt callback. The inner call waits for the outer one, which never finishes.

## Platform setup

Declaring a permission in code is not enough. Each platform also needs it in native files. A missing entry does not crash the app. The permission is simply always denied, so check this section first when a request "does nothing".

You can print the exact snippets for the tags your app uses:

```dart
const used = [AppPermission.camera, AppPermission.photos, AppPermission.location];
debugPrint(PermissionSetup.androidManifest(used));
debugPrint(PermissionSetup.iosInfoPlist(used));
debugPrint(PermissionSetup.iosPodfile(used));
```

### Android: `android/app/src/main/AndroidManifest.xml`

Add the `<uses-permission>` lines inside `<manifest>` and above `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <application ...>
```

Set `compileSdk` to 35 or higher in `android/app/build.gradle`.

### iOS: `ios/Runner/Info.plist`

Every permission needs a usage description. App Review rejects vague texts such as "needed for the app". Say what the user gets.

```xml
<key>NSCameraUsageDescription</key>
<string>Take a profile photo.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Choose a photo from your library.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Show stores near you.</string>
```

### iOS: compiling permissions in

permission_handler compiles out permissions your app does not use, and a compiled-out permission always reports `denied`.

**Swift Package Manager (Flutter's default):** permissions are detected from the `Info.plist` keys. Notifications are enabled by default. After changing keys, clear the cache once:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**CocoaPods:** list each macro in `ios/Podfile`. Use `PermissionSetup.iosPodfile(...)` or copy this pattern:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_LOCATION_WHENINUSE=1',
      ]
    end
  end
end
```

## Permission reference

This table is generated from `lib/src/permissions/permission_registry.dart`. Do not edit it by hand. See [Adding a new permission](#adding-a-new-permission).

<!-- PERMISSIONS:BEGIN -->
| Tag | Android native | iOS native | AndroidManifest.xml | Info.plist | Podfile macro |
|---|---|---|---|---|---|
| `camera` | `camera` | `camera` | `CAMERA` | `NSCameraUsageDescription` | `PERMISSION_CAMERA` |
| `microphone` | `microphone` | `microphone` | `RECORD_AUDIO` | `NSMicrophoneUsageDescription` | `PERMISSION_MICROPHONE` |
| `photos` | API ≤ 32: `storage`<br>API 33+: `photos` | `photos` | `READ_MEDIA_IMAGES`<br>`READ_MEDIA_VISUAL_USER_SELECTED`<br>`READ_EXTERNAL_STORAGE` (≤ API 32) | `NSPhotoLibraryUsageDescription` | `PERMISSION_PHOTOS` |
| `videos` | API ≤ 32: `storage`<br>API 33+: `videos` | `photos` | `READ_MEDIA_VIDEO`<br>`READ_MEDIA_VISUAL_USER_SELECTED`<br>`READ_EXTERNAL_STORAGE` (≤ API 32) | `NSPhotoLibraryUsageDescription` | `PERMISSION_PHOTOS` |
| `audio` | API ≤ 32: `storage`<br>API 33+: `audio` | `mediaLibrary` | `READ_MEDIA_AUDIO`<br>`READ_EXTERNAL_STORAGE` (≤ API 32) | `NSAppleMusicUsageDescription` | `PERMISSION_MEDIA_LIBRARY` |
| `storage` | API ≤ 32: `storage`<br>API 33+: — | — | `READ_EXTERNAL_STORAGE` (≤ API 32)<br>`WRITE_EXTERNAL_STORAGE` (≤ API 29) | — | — |
| `location` | `locationWhenInUse` | `locationWhenInUse` | `ACCESS_FINE_LOCATION`<br>`ACCESS_COARSE_LOCATION` | `NSLocationWhenInUseUsageDescription` | `PERMISSION_LOCATION_WHENINUSE` |
| `locationAlways` | `locationWhenInUse`, `locationAlways` | `locationWhenInUse`, `locationAlways` | `ACCESS_FINE_LOCATION`<br>`ACCESS_COARSE_LOCATION`<br>`ACCESS_BACKGROUND_LOCATION` | `NSLocationWhenInUseUsageDescription`<br>`NSLocationAlwaysAndWhenInUseUsageDescription` | `PERMISSION_LOCATION` |
| `notification` | API ≤ 32: —<br>API 33+: `notification` | `notification` | `POST_NOTIFICATIONS` | — | `PERMISSION_NOTIFICATIONS` |
| `contacts` | `contacts` | `contacts` | `READ_CONTACTS`<br>`WRITE_CONTACTS` | `NSContactsUsageDescription` | `PERMISSION_CONTACTS` |
| `calendar` | `calendarFullAccess` | `calendarFullAccess` | `READ_CALENDAR`<br>`WRITE_CALENDAR` | `NSCalendarsFullAccessUsageDescription`<br>`NSCalendarsUsageDescription` | `PERMISSION_EVENTS_FULL_ACCESS`<br>`PERMISSION_EVENTS` |
| `bluetooth` | API ≤ 30: `locationWhenInUse`<br>API 31+: `bluetoothScan`, `bluetoothConnect` | `bluetooth` | `BLUETOOTH_SCAN`<br>`BLUETOOTH_CONNECT`<br>`BLUETOOTH` (≤ API 30)<br>`BLUETOOTH_ADMIN` (≤ API 30)<br>`ACCESS_FINE_LOCATION` (≤ API 30) | `NSBluetoothAlwaysUsageDescription` | `PERMISSION_BLUETOOTH` |
| `motion` | API ≤ 28: —<br>API 29+: `activityRecognition` | `sensors` | `ACTIVITY_RECOGNITION` | `NSMotionUsageDescription` | `PERMISSION_SENSORS` |
| `bodySensors` | `sensors` | — | `BODY_SENSORS` | — | — |
| `speech` | `microphone` | `speech`, `microphone` | `RECORD_AUDIO` | `NSSpeechRecognitionUsageDescription`<br>`NSMicrophoneUsageDescription` | `PERMISSION_SPEECH_RECOGNIZER`<br>`PERMISSION_MICROPHONE` |
| `phone` | `phone` | — | `READ_PHONE_STATE`<br>`CALL_PHONE` | — | — |
| `sms` | `sms` | — | `SEND_SMS`<br>`READ_SMS`<br>`RECEIVE_SMS` | — | — |
| `appTracking` | — | `appTrackingTransparency` | — | `NSUserTrackingUsageDescription` | `PERMISSION_APP_TRACKING_TRANSPARENCY` |
| `exactAlarm` | API ≤ 30: —<br>API 31+: `scheduleExactAlarm` | — | `SCHEDULE_EXACT_ALARM` | — | — |
| `batteryOptimization` | `ignoreBatteryOptimizations` | — | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | — | — |
| `reminders` | — | `reminders` | — | `NSRemindersFullAccessUsageDescription`<br>`NSRemindersUsageDescription` | `PERMISSION_REMINDERS` |

**Notes per tag**

- `photos`: Android 12 and lower use READ_EXTERNAL_STORAGE.
- `videos`: iOS has one photo library permission for images and videos.
- `storage`: Not applicable on Android 13+: use photos, videos or audio, or the system file picker.
- `storage`: Not applicable on iOS: apps use their own sandbox.
- `location`: Android 12+ users may grant approximate location only.
- `locationAlways`: Foreground location is requested first; both platforms require it.
- `locationAlways`: Android 11+ sends the user to settings for "Allow all the time".
- `notification`: No Info.plist key is needed.
- `notification`: Granted automatically on Android 12 and lower.
- `calendar`: NSCalendarsUsageDescription covers iOS 16 and lower.
- `bluetooth`: Android 11 and lower need location permission to find BLE devices.
- `bluetooth`: If you also use AppPermission.location, drop maxSdkVersion from ACCESS_FINE_LOCATION.
- `bodySensors`: Not applicable on iOS: health data goes through HealthKit.
- `speech`: Android only needs the microphone; iOS also needs speech recognition.
- `phone`: Not applicable on iOS.
- `sms`: Not applicable on iOS. Google Play restricts SMS permissions.
- `appTracking`: Not applicable on Android.
- `exactAlarm`: Opens a system settings page instead of a dialog.
- `batteryOptimization`: Google Play only allows this for specific app types.
- `reminders`: Not applicable on Android.
<!-- PERMISSIONS:END -->

## Adding a new permission

1. Add the tag to `AppPermission` in `lib/src/permissions/app_permission.dart`.
2. Add a `PermissionSpec` for it in `lib/src/permissions/permission_registry.dart`. Fill in the Android mapping per SDK level, the iOS mapping, the manifest entries, the Info.plist keys and the Podfile macros. Use an empty list where a platform has no runtime permission.
3. Regenerate the reference table:

   ```bash
   UPDATE_PERMISSION_DOCS=1 flutter test test/permissions_test.dart
   ```

4. Add a line to the [change log](#change-log) below.
5. Run `flutter test`. The docs test fails if this file is out of date, and the registry test fails if a tag has no mapping.

The same steps apply when you change a mapping, for example when a new Android version introduces a new permission.

## Known platform behaviour

- **Android before the first request.** `check()` returns `denied` both for "never asked" and for "don't ask again". Only a request tells them apart, and `ensure()` handles this case.
- **Android 11 and higher, background location.** "Allow all the time" is chosen on a settings page, not in a dialog. Foreground location is always requested first.
- **Android 14 and higher, partial media.** With `READ_MEDIA_VISUAL_USER_SELECTED` declared, the user can pick individual photos, and the status is `limited`.
- **iOS denial.** A single "Don't Allow" is final. The status becomes `permanentlyDenied`, and only Settings can change it.
- **iOS changes in Settings.** Turning a permission off in Settings restarts the app. This is iOS behaviour and not a crash.
- **Web and desktop.** Every tag reports `notApplicable`, and the browser or OS asks on first use.

## Change log

| Date | Change |
|---|---|
| 2026-09-25 | First version: 21 tags, Android and iOS mappings, `ensure()` flow, request queue, setup snippet generator. |
