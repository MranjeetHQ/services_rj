# services_rj features

Everything the package provides today, the extension points for adding your own behaviour, and the roadmap of planned features. The package exists to make the **initial setup of a Flutter app** short: one call at start-up, one app widget, and the common building blocks ready to use.

Keep this file current: add a row when a feature ships and move roadmap items to the matching section when they are done.

**Status:** ✅ available · 🆕 new in the next release · 🗺️ planned

---

## Contents

- [Start a new app](#start-a-new-app)
- [1. App setup and control](#1-app-setup-and-control)
- [2. Theming](#2-theming)
- [3. Storage and security](#3-storage-and-security)
- [4. Networking](#4-networking)
- [5. API caching](#5-api-caching)
- [6. Connectivity](#6-connectivity)
- [7. Permissions](#7-permissions)
- [8. Dynamic forms](#8-dynamic-forms)
- [9. Widgets](#9-widgets)
- [10. Helpers](#10-helpers)
- [Extension points](#extension-points)
- [Roadmap](#roadmap)

---

## Start a new app

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:services_rj/services_rj.dart';

Future<void> main() => AppSetup.run(
  features: const AppFeatures(sharedPref: true, theme: true, logger: true),
  themeConfig: const AppThemeConfig(
    seedColor: Colors.indigo,
    initialThemeMode: ThemeMode.system,
    borderRadius: 14,
  ),
  orientations: const [DeviceOrientation.portraitUp],
  onError: (error, stack) {
    // Send to your crash reporter.
  },
  app: const ServicesApp(title: 'My app', home: HomePage()),
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemeModeSelector(),
          SizedBox(height: 16),
          ThemeColorPicker(),
        ],
      ),
    ),
  );
}
```

This starts the binding, installs error handlers, locks the orientation, initializes shared preferences and the theme, and runs an app whose theme mode and accent colour the user can change and that are remembered across launches.

---

## 1. App setup and control

| Status | Feature | API | Notes |
|---|---|---|---|
| 🆕 | One-call start-up | `AppSetup.run(...)` | Binding, `FlutterError.onError` + `PlatformDispatcher.onError` routed to `onError`, `orientations`, `systemUiOverlayStyle`, `AppController.initialize`, `beforeRun` for your own async setup, then `runApp`. A setup failure is reported to `onError` and the app still starts; without `onError` it is rethrown. |
| 🆕 | Pre-wired app widget | `ServicesApp`, `ServicesApp.router` | `MaterialApp` that follows `AppThemeController` (config, saved mode, accent colour), attaches `AppKeys`, hides the debug banner. All common `MaterialApp` options; `theme` / `darkTheme` / `themeMode` override the controller. `.router` takes a `RouterConfig` (go_router etc.). |
| 🆕 | Global navigator and messenger | `AppKeys.navigator`, `AppKeys.messenger`, `AppKeys.context` | Navigate or show a snackbar from services and callbacks without a `BuildContext`. |
| ✅ | Feature switchboard | `AppController.initialize`, `AppFeatures`, `AppFeature` | Opt-in features: `sharedPref`, `theme`, `network`, `apiCache`, `encryption`, `connectivity`, `logger`, `networkLogs`, `permissions`. Started in dependency order. 🆕 `themeConfig` parameter. |
| ✅ | Runtime switches | `AppController.instance.setEnabled` | `apiCache`, `connectivity`, `logger`, `networkLogs`, `permissions`. |
| ✅ | Readiness checks | `isEnabled`, `isReady`, typed accessors (`api`, `dio`, `cache`, `theme`, `encryption`, `permissions`, `auth`) | An accessor for a feature that is off throws a `StateError`. |
| ✅ | Data lifecycle | `logout()`, `wipeAllData(destroyEncryptionKey:)` | |
| ✅ | Legacy initializer | `AppInitializer.initialize` | Forwards to `AppController`. |

## 2. Theming

| Status | Feature | API | Notes |
|---|---|---|---|
| ✅ | One config for light and dark | `AppThemeConfig` → `AppThemeManager.lightTheme` / `darkTheme` | Seed colour, Material 3, radii, font, scaffold / background / surface colours, button styles, icon colour. Styles app bar, bottom navigation, cards, elevated / outlined / text buttons, inputs, chips, dialogs, icons. |
| 🆕 | First-launch theme mode | `AppThemeConfig.initialThemeMode` | Used until the user picks a mode. |
| 🆕 | Full colour schemes | `lightColorScheme`, `darkColorScheme` | Replace the seed-generated scheme, e.g. for exact brand colours. |
| 🆕 | Typography and density | `textTheme` (merged over the default), `visualDensity` | |
| 🆕 | App bar and input options | `appBarCenterTitle`, `appBarElevation`, `inputFilled` | |
| 🆕 | Design tokens | `extensions` (`ThemeExtension`s) | Read with `Theme.of(context).extension<T>()`. |
| 🆕 | Anything else | `customize: (theme, brightness) => ...` | Runs last on both themes. |
| 🆕 | Config copies | `AppThemeConfig.copyWith` | |
| 🆕 | Single theme builder | `AppThemeManager.theme(config, brightness)` | |
| ✅ | Theme mode, saved | `AppThemeController.setThemeMode`, `toggleTheme`, `themeMode`, `isDarkMode` … | Saved when `sharedPref` is on (encrypted when `encryption` is on). |
| 🆕 | User accent colour, saved | `setSeedColor(color)`, `seedColor`, `hasCustomSeedColor` | `null` returns to the config colour. |
| 🆕 | Runtime config change | `setConfig(config)` | e.g. switching brands or white-label tenants. |
| 🆕 | Ready-made themes | `AppThemeController.lightTheme` / `darkTheme` | Built once and cached until something changes. |
| 🆕 | Reset | `resetToDefaults()` | Forgets the saved mode and accent colour. |
| 🆕 | Settings widgets | `ThemeModeSelector`, `ThemeColorPicker` | Light / System / Dark segmented control; accent swatches with a Default swatch. Labels and colours configurable. |
| ✅ | Dark mode switch | `ThemeModeSwitcher` | |

## 3. Storage and security

| Status | Feature | API | Notes |
|---|---|---|---|
| ✅ | Typed preferences | `SharedPrefManager.saveData` / `getData<T>` / `delete` / `containsKey` / `getKeys` / `clearAllSharedPrefData` | String, int, double, bool, `List<String>`, JSON maps. |
| ✅ | Shared keys | `SharedPrefKeys` | Auth token, refresh token, name, demo user, theme mode, 🆕 theme seed colour. |
| ✅ | Encryption at rest | `AppEncryption`, `encryption` feature | AES-256-GCM for preferences and cache files; key in Keychain / Keystore; custom `EncryptionKeyProvider`. |
| ✅ | Migration | `SharedPrefManager.migrateToEncrypted` | Converts existing plain values. |
| ✅ | Auth tokens | `AuthTokenService` | Save, read, clear, logout; the auth interceptor refreshes on 401. |

## 4. Networking

| Status | Feature | API | Notes |
|---|---|---|---|
| ✅ | Configuration | `ApiConfig` | Base URL, timeouts, default headers, token header, refresh endpoint, callbacks (`onUnauthorized`, `onSessionExpired`, `onUserBanned`, `onError`), log flags. |
| ✅ | HTTP client | `DioService`, `ApiClient.request(ApiRequest)` | Typed `ApiResponse`, `ApiException`, `ApiMethod`, `RequestType`. |
| ✅ | Interceptors | auth (401 refresh and retry), retry, error, logger; `addInterceptor` / `addInterceptors` | |
| ✅ | Uploads and downloads | `ApiRequest(files:, downloadSavePath:)`, `UploadProgress`, `DownloadProgress` | Multipart uploads and file downloads with progress. |
| ✅ | Cancellation | `CancelRequest` | |
| ✅ | Logging | `networkLogs` feature, `printLogs` | |

## 5. API caching

| Status | Feature | API | Notes |
|---|---|---|---|
| ✅ | Memory and disk cache | `ApiCacheManager`, `CacheConfig` | Preloads at start-up. |
| ✅ | Policies | `CachePolicy`: `staleWhileRevalidate` (default), `networkFirst`, `cacheFirst`, `cacheOnly`, `networkOnly` | Per request: `cachePolicy`, `cacheTtl`, `cacheKey`, `forceRefresh`. |
| ✅ | Live data | `ApiClient.watch`, `peek`, `onRevalidated` | Cached data on the first frame, fresh data after. |
| ✅ | Invalidation | `invalidateCache: ['/posts']` | |
| ✅ | Offline | Serves cache when offline; shares identical in-flight requests; per-user scope. | |

## 6. Connectivity

| Status | Feature | API |
|---|---|---|
| ✅ | Online / offline state and stream | `AppConnectivity.hasInternet()`, `stream`, `startMonitoring()` |

## 7. Permissions

| Status | Feature | API | Notes |
|---|---|---|---|
| ✅ | Platform-independent tags | `AppPermission` | camera, microphone, photos, videos, audio, storage, location, locationAlways, notification, contacts, calendar, bluetooth, motion, bodySensors, speech, phone, sms, appTracking, exactAlarm, batteryOptimization. Mapped per platform and Android version. |
| ✅ | Queued requests | `AppPermissionManager.ensure()` | Explain, ask, offer settings; Material prompts. |
| ✅ | Setup snippets | `PermissionSetup.androidManifest`, `iosInfoPlist`, `iosPodfile` | Generates the platform entries. See [docs/permissions.md](docs/permissions.md). |
| ✅ | Pluggable backend | `PermissionBackend`, `PermissionRegistry` | |

## 8. Dynamic forms

Full reference: [docs/forms.md](docs/forms.md) and the [live guide](https://mranjeethq.github.io/services_rj/).

| Status | Feature | Notes |
|---|---|---|
| ✅ | JSON-driven forms | `DynamicForm`, `DynamicFormController`, `MultiStepForm`; JSON map or string. |
| ✅ | 50+ field types | Text inputs (text, textarea, password, email, number, decimal, phone, url, search, otp, pin), date and time, selection (dropdown, multiselect, searchableDropdown, checkbox / radio groups, switch, chips, toggleButtons, segmented), sliders, rating, stepper, colour picker, media (image, camera, file, signature, QR / barcode scanner), location (country, state, city), autocomplete / typeahead, rich text / markdown / HTML editor, layout (label, divider, spacer, section header, expansion, group), `repeater`, hidden / read-only, `custom`. |
| ✅ | Validation | `required`, `email`, `phone`, `url`, `number`, `decimal`, `min`, `max`, `minLength`, `maxLength`, `regex`, `matchField`, `passwordStrength`, `minItems`, `maxItems`; custom validators via `ValidatorRegistry`. |
| ✅ | Text presets | `name`, `mobile`, `phone`, `pan`, `aadhaar`, `gst`, `ifsc`, `pincode`, `vehicleNumber`, `voterId`, `passport`, `upiId`, `custom`; `TextPresets.register`. |
| ✅ | Phone country code | Picker with flags and search; `PhoneFormat` combined / separate. |
| ✅ | Conditional logic | `visibleWhen`, `requiredWhen`, custom operators. |
| ✅ | Edit mode and dirty tracking | `initialData`, reset, dirty state. |
| ✅ | Styling | `DynamicFormThemeData`, per-field style keys, `optionStyle` (standard / card / chip / button), label position, required marks, spacing names, `FieldOverrides`. |
| ✅ | Searchable dropdowns | Local, loaded-once and search-as-you-type sources (`FormSearchSources`). |
| ✅ | Enums | `FormEnumRegistry`, `getEnum`, `getEnumList`. |
| ✅ | Languages | English, Hindi, Arabic, Spanish, French, German. |

## 9. Widgets

| Status | Widget | Notes |
|---|---|---|
| 🆕 | `ServicesApp` | See [App setup](#1-app-setup-and-control). |
| 🆕 | `ThemeModeSelector`, `ThemeColorPicker` | See [Theming](#2-theming). |
| ✅ | `AppButtons` | elevated, filled, outlined, text, tonal, icon, FAB, extended FAB, custom; named constructors. |
| ✅ | `AppScaffold` | Scaffold with a `SafeArea` body. |
| ✅ | `PrimaryLoader` | Sized progress indicator. |
| ✅ | `ThemeModeSwitcher` | Dark mode switch. |

## 10. Helpers

| Status | Helper | API |
|---|---|---|
| ✅ | Logger | `AppLogger.info` / `warning` / `error` (debug builds, `logger` feature) |
| ✅ | Snackbars | `AppSnackbar.show` / `success` / `error` |
| ✅ | Dialogs | `AppDialogs.showLoading` / `showMessage` |
| ✅ | Responsive checks | `AppResponsive.isMobile` / `isTablet` / `isDesktop` |
| ✅ | Validators | `AppValidators.email` / `password` / `requiredField` |
| ✅ | Debouncer | `AppDebouncer.run` |
| ✅ | Context extensions | `context.theme`, `colors`, `textTheme`, `isDarkMode`, `screenSize`, `screenWidth`, `screenHeight` |
| 🆕 | String extensions | Checks (`isBlank`, `isEmail`, `isPhone`, `isUrl`, `isNumeric`, `isAlphabetic`, …), conversions (`toIntOrNull`, `toDoubleOrNull`, `toBool`), case (`capitalize`, `toTitleCase`, `toCamelCase`, `toSnakeCase`, `toKebabCase`), editing (`truncate`, `mask`, `initials`, `onlyDigits`, …); on `String?`: `isNullOrEmpty`, `isNullOrBlank`, `orEmpty`, `or(fallback)`. Emoji- and Hindi-safe. |
| 🆕 | Double and number extensions | `roundTo`, `isWhole`, `toCleanString`, `orZero`; on any number: `withSeparators`, `toCurrency`, `toCompact` (K / M / B / T or K / L / Cr), `toPercent`, `isBetween`, `heightBox`, `widthBox`, `allInsets`, `horizontalInsets`, `verticalInsets`, `borderRadius`. |

---

## Extension points

Ways to add behaviour without changing the package:

| Area | Hook |
|---|---|
| Start-up | `AppSetup.run(beforeRun: ...)` for app-specific async setup; `onError` for crash reporting |
| Theme | `AppThemeConfig.customize`, `extensions`, `lightColorScheme` / `darkColorScheme`, `AppThemeController.setConfig` |
| App widget | `ServicesApp(builder: ...)` for app-wide overlays or `MediaQuery` changes; `ServicesApp.router` for any router |
| Networking | `DioService.addInterceptor`, `ApiConfig` callbacks |
| Encryption | `EncryptionKeyProvider` |
| Permissions | `PermissionBackend`, `PermissionRegistry` |
| Buttons | `AppButtons(type: AppButtonType.custom, customBuilder: ...)` |
| Extensions | Add members in `lib/src/core/*extensions.dart` and document them in [docs/extensions.md](docs/extensions.md); a test enforces it |
| Forms | `ValidatorRegistry`, `TextPresets.register`, `ConditionEvaluator.registerOperator`, `FieldUtils.registerIcon`, `FormSearchSources.register`, `FormEnumRegistry`, `FieldOverrides` (per id or per type) |

---

## Roadmap

Planned features that would further shorten a new project's setup, with the API they would most likely take. **P1** comes next; **P3** is nice to have. None of these exist yet.

### P1: setup essentials

| Feature | Proposed API | Why |
|---|---|---|
| Environments and flavours | `AppEnvironment.dev / staging / prod` with per-environment `ApiConfig`, read from `--dart-define`; `AppSetup.run(environment: ...)` | Every app needs separate API URLs and keys per build. |
| Start-up splash | `AppSetup.run(splash: Widget)` shown while initialization runs, with progress | Avoids a blank screen during encryption, preferences and cache warm-up. |
| Context-free UI helpers | `AppSnackbar.global(...)`, `AppDialogs.global(...)` using `AppKeys` | Show feedback from services and API callbacks. |
| Crash reporting adapter | `AppErrorReporter` interface (Sentry, Crashlytics) passed to `AppSetup.run` | Standard place for `onError`, with user and breadcrumb context. |
| Auth flow helpers | Session state stream; redirect to a login route on `onSessionExpired`; route guard | Every logged-in app re-implements this. |

### P2: common app settings

| Feature | Proposed API | Why |
|---|---|---|
| Locale manager | `AppLocaleController` (saved locale, `LocaleSelector` widget) wired into `ServicesApp` | Same pattern as theme mode, for languages. |
| Text size setting | `AppThemeController.textScale` (saved) and a clamp option on `ServicesApp` | Accessibility setting most apps expose. |
| Dynamic colour | `AppThemeConfig(useDynamicColor: true)` using the Android 12+ wallpaper palette | Material You look without extra code. |
| First-launch and onboarding | `AppFirstRun.isFirstLaunch`, `markOnboarded()` | Show onboarding once. |
| App info and update check | `AppInfo.version` / `buildNumber`; optional force-update prompt | Version on settings screens; minimum-version enforcement. |
| Responsive layout widget | `ResponsiveLayout(mobile:, tablet:, desktop:)`, configurable breakpoints | Builds on `AppResponsive`. |
| Async UI states | `ApiResponseBuilder` with loading / empty / error / data slots; paged list with pull-to-refresh | Removes repeated boilerplate around `ApiClient`. |

### P3: advanced

| Feature | Proposed API | Why |
|---|---|---|
| Offline mutation queue | Queue POST / PUT / DELETE while offline and replay when back online | Completes offline-first support. |
| In-app network log viewer | `NetworkLogScreen` | Debug API calls on a device. |
| Analytics adapter | `AppAnalytics` interface with screen tracking through `ServicesApp` observers | One place for analytics. |
| Feature flags / remote config | `AppFlags` adapter with local defaults | Toggle features without a release. |
| Project scaffolding | `dart run services_rj:create` to generate `main.dart`, folders and config | Fastest possible new project setup. |
