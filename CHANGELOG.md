## 1.2.0

* **Dynamic forms**: JSON-driven form builder (`DynamicForm`, `DynamicFormController`) with 53 field types, validation, conditional logic, multi-step wizards, edit mode, dirty tracking, theming and six built-in languages. Based on json_form_engine by Rupesh Rajak (MIT, see `THIRD_PARTY_NOTICES.md`). Also available alone through `package:services_rj/forms.dart`.
* **Enums**: typed enums for every string option (`ValidatorType`, `ConditionOperator`, `KeyboardKind`, `InputActionKind`, `TextCase`, `OptionLayout`, `LabelBehavior`, `MediaSource`). `FormEnumRegistry` turns Dart enums into options (`"enum": "Plan"`), and `getEnum` / `getEnumList` read them back.
* **Extendable forms**: new `repeater` type for add / remove / reorder entries with `minItems` / `maxItems`; `allowCustomOptions` lets users add their own option; `addOption`, `removeOption` and `onOptionAdded`; `minItems` / `maxItems` validators.
* **Per-field customization**: `prefixText`, `suffixText`, `textCase`, `maxLines`, `minLines`, `showCounter`, `tooltip`, `optionLayout` + `columns`, option `description`; style keys `activeColor`, `iconColor`, `cursorColor`, `textAlign`, `helperStyle`, `errorStyle`, `containerColor`, `containerRadius`. `FieldOverrides` (per id or per type) can replace the widget, style, decoration, option rendering, wrapper or text.
* **Extensibility**: `ConditionEvaluator.registerOperator`, `FieldUtils.registerIcon`, `toJson()` on every config model.
* **Example app** in `example/` and a guide website in `form_guide_web/`, kept in sync by tests.
* SDK constraint relaxed to `^3.10.0`.

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