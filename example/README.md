# services_rj example

A playground that demonstrates every feature of `services_rj`.

```bash
cd example
flutter pub get
flutter run            # pick an Android or iOS device/emulator
```

Mobile is the intended target: the API cache and secure storage need `dart:io`
and platform plugins, so the web build only runs the form demos.

`main()` starts the app with `AppSetup.run` and **every** feature on, so all
pages are live, and the root widget is a `ServicesApp`. A real app enables only
what it uses.

## What is on the home screen

| Section | Demos |
|---|---|
| Forms — examples | Meetup RSVP, edit mode, job wizard, styling lab |
| Forms — every field type | Six galleries covering every `FieldType`, including pluggable adapters (signature, scanners, rich/markdown/HTML editors, custom type) |
| Forms — feature labs | Validators (all `ValidatorType`s, custom and registered), conditional logic (all `ConditionOperator`s), localization (en, hi, ar, es, fr, de, plus a custom locale), controller playground, form theme and overrides, typed Dart config and async options, multi-step and repeaters |
| Core | **App setup** (`AppSetup.run` options, `ServicesApp`, `AppKeys` snackbar / dialog / navigation from plain functions, a theme settings screen), `AppController` feature switches, storage (`SharedPrefManager`), encryption, **theme** (every `AppThemeConfig` option including `initialThemeMode`, colour schemes, `textTheme`, `visualDensity`, app bar, inputs, `extensions` and `customize`; light/dark previews; apply to the whole app with `setConfig`; `ThemeModeSelector`, `ThemeColorPicker`, `resetToDefaults`), `AppButtons`, snackbar/dialogs/responsive/context extensions, **extensions** (every `String`, `String?`, `double` and number extension on live input), validators and debouncer, logger and connectivity |
| Networking, cache, permissions | API playground (all methods, errors, cancel, upload/download), cache lab (all `CachePolicy` values, `watch`, `peek`, invalidation), auth and interceptors, permissions (all 21 `AppPermission` tags), setup generator for AndroidManifest/Info.plist/Podfile |

The network demos call `jsonplaceholder.typicode.com` and `httpbin.org`, so they
need an internet connection. The AndroidManifest, Info.plist and Podfile in this
app already include the permission entries the demos need.

## Tests

```bash
flutter test
```

The tests check that every `FieldType`, `ValidatorType` and `ConditionOperator`
is used by a demo, so a new value added to the package fails here until it is
demonstrated. Network tests use a local loopback server.
