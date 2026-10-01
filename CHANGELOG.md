## 1.1.0

* **AppController**: one entry point that initializes and controls every feature. All features are on by default and can be switched off with `AppFeatures`. Logging, network logs, cache, connectivity and permissions can also change at runtime.
* **API caching**: memory and disk cache with stale-while-revalidate as the default, plus `networkFirst`, `cacheFirst`, `cacheOnly` and `networkOnly`. It preloads at start-up, serves cache instantly when offline, shares identical requests, invalidates after mutations, and supports per-user scope. `ApiClient.watch()` and `peek()` are new.
* **Encryption**: AES-256-GCM for SharedPreferences values and cache files, with the key kept in the Keychain or Keystore. Existing plain values still read, and `migrateToEncrypted()` converts them.
* **Permissions**: `AppPermission` tags mapped per platform and Android version onto permission_handler, a queued `AppPermissionManager` with an `ensure()` flow, Material prompts, setup snippet generators, and `docs/permissions.md` kept in sync by a test.
* **Fixes**: 2xx responses other than 200 and 201 were treated as errors. Non-JSON error bodies crashed the handler, and `ApiException` crashed the exception handler. Networking, cache and button classes are now exported.
* **Tests**: 79 tests, including one regression test per QA finding. See `docs/qa_report.md`.

## 1.0.0

* **Networking**: Added DioService with safe lazy initialization, `addInterceptor()`/`addInterceptors()` APIs, `printLogs` config flag, `AuthTokenService` for token persistence, and `AuthTokenInterceptor` with automatic 401 refresh+retry.

* **Theming**: Extended `AppThemeConfig` with separate `cardRadius`, background/surface colours, outlined button border, elevation, and per-button text styles. `AppThemeManager` now styles AppBar, BottomNavigation, Card, Elevated/Outlined/Text buttons, InputDecoration, Chip, Dialog, and Icon.

* **Widgets**: New `AppButtons` widget with `AppButtonType` enum, 8 named factory constructors, and full extensibility via `customBuilder` or subclassing.

* **Core**: `SharedPrefKeys` gains `refreshToken` key. `AppInitializer`, `AppThemeController`, and `SharedPrefManager` unchanged but fully integrated.

* **Docs**: Comprehensive README with quick start, feature walkthroughs, and a complete end-to-end example.