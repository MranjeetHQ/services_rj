# services_rj

[![CI](https://github.com/MranjeetHQ/services_rj/actions/workflows/ci.yml/badge.svg)](https://github.com/MranjeetHQ/services_rj/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Live guide](https://img.shields.io/badge/guide-live-00796B.svg)](https://mranjeethq.github.io/services_rj/)

A Flutter utility package that provides out‑of‑the‑box support for **networking** with **offline caching**, **encrypted storage**, **runtime permissions**, **JSON-driven dynamic forms**, **theming**, **button widgets**, **shared preferences**, and common app‑level helpers. One `AppController` switches every feature on or off.

**Guides:** [Feature list and roadmap](FEATURES.md) · [Extensions](docs/extensions.md) · [AppController, caching and encryption](docs/app_controller.md) · [Permissions](docs/permissions.md) · [Dynamic forms](docs/forms.md) · [Live form guide](https://mranjeethq.github.io/services_rj/) (with an element builder, source in [form_guide_web/](form_guide_web/)) · [Release notes](RELEASE_NOTES.md) · [QA report](docs/qa_report.md)

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Feature list and roadmap](FEATURES.md)
- [Features](#features)
  - [1. Networking](#1-networking)
    - [ApiConfig](#apiconfig)
    - [DioService](#dioservice)
    - [ApiClient](#apiclient)
    - [Custom Interceptors](#custom-interceptors)
    - [Logging with Print Control](#logging-with-print-control)
  - [2. Theming](#2-theming)
    - [AppThemeConfig](#appthemeconfig)
    - [AppThemeManager](#appthememanager)
    - [AppThemeController](#appthemecontroller)
    - [Theme settings widgets](#theme-settings-widgets)
    - [Multi‑Button Theme Support](#multi-button-theme-support)
  - [3. Reusable Button Widget](#3-reusable-button-widget)
    - [AppButtonType Enum](#appbuttontype-enum)
    - [Named Factory Constructors](#named-factory-constructors)
    - [Custom / Extensibility](#custom--extensibility)
  - [4. Core Utilities](#4-core-utilities)
    - [AppSetup and ServicesApp](#appsetup-and-servicesapp)
    - [AppKeys](#appkeys)
    - [AppInitializer](#appinitializer)
    - [SharedPrefManager](#sharedprefmanager)
    - [String and number extensions](#string-and-number-extensions)
    - [Other Helpers](#other-helpers)
  - [5. Dynamic Forms](#5-dynamic-forms)
  - [6. AppController, caching and encryption](#6-appcontroller-caching-and-encryption)
  - [7. Permissions](#7-permissions)
- [Example](#example)

---

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  services_rj: ^1.2.0
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

`AppSetup.run` starts the app in one call and `ServicesApp` is a `MaterialApp` already wired to the theme, the saved theme mode and accent colour, and global navigator keys:

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

`AppSetup.run` also takes `apiConfig`, `cacheConfig`, `encryptionKeyProvider`, `systemUiOverlayStyle` and `beforeRun` (your own async setup). Every feature, extension point and the roadmap are listed in [FEATURES.md](FEATURES.md).

<details>
<summary>Manual setup with <code>AppController</code> and <code>MaterialApp</code></summary>

```dart
void main() async {
  await AppController.initialize(
    features: const AppFeatures(sharedPref: true, theme: true, network: true),
    themeConfig: const AppThemeConfig(seedColor: Colors.teal),
    apiConfig: ApiConfig(baseUrl: 'https://jsonplaceholder.typicode.com'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeController.instance;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) => MaterialApp(
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.themeMode,
        navigatorKey: AppKeys.navigatorKey,
        scaffoldMessengerKey: AppKeys.scaffoldMessengerKey,
        home: const HomeScreen(),
      ),
    );
  }
}
```

`AppInitializer.initialize(...)` is still supported. It forwards to `AppController`.

</details>

### New: `AppController` (recommended for new apps)

One switchboard for every feature: shared preferences, theme, networking, **API caching**, **AES-256-GCM encryption**, connectivity, logging and **permissions**. Features are opt-in:

```dart
await AppController.initialize(
  features: const AppFeatures(sharedPref: true, theme: true),
);
```

See [AppController, caching and encryption](docs/app_controller.md).

---

## Features

### 1. Networking

#### ApiConfig

Holds all network‑related configuration:

| Field                | Type                   | Default          | Description                                    |
|----------------------|------------------------|------------------|------------------------------------------------|
| `baseUrl`            | `String`               | **required**     | API base URL                                   |
| `connectTimeout`     | `int`                  | `30000`          | Connection timeout (ms)                        |
| `receiveTimeout`     | `int`                  | `30000`          | Receive timeout (ms)                           |
| `sendTimeout`        | `int`                  | `30000`          | Send timeout (ms)                              |
| `enableLogs`         | `bool`                 | `true`           | Enable Dio logs                                |
| `printLogs`          | `bool`                 | `false`          | Print network logs to console                  |
| `defaultHeaders`     | `Map<String, dynamic>` | `{}`             | Default request headers                        |
| `onUnauthorized`     | callback               | `null`           | Called on 401                                  |
| `onSessionExpired`   | callback               | `null`           | Called on session expiry                       |
| `onUserBanned`       | callback               | `null`           | Called when user is banned                     |
| `onError`            | callback               | `null`           | Global error callback                          |

#### DioService

Singleton that initialises and manages the Dio instance.

```dart
// Opt in to networking during app initialization.
await AppController.initialize(
  features: const AppFeatures(network: true),
  apiConfig: config,
);

// Access the Dio instance
final response = await DioService.instance.dio.get('/posts');

// 🔁 Add interceptors after initialisation
DioService.instance.addInterceptor(MyCustomInterceptor());

// Add multiple at once
DioService.instance.addInterceptors([interceptor1, interceptor2]);
```

**Safe access** – accessing `dio` before `initialize()` throws a descriptive `StateError`.

#### ApiClient

High‑level client that wraps Dio for normal, upload, and download requests.

```dart
final apiClient = ApiClient.instance;

// Normal GET request
final response = await apiClient.request(
  ApiRequest(
    endpoint: '/posts',
    method: ApiMethod.get,
  ),
);

// Upload a file
final uploadResponse = await apiClient.request(
  ApiRequest(
    endpoint: '/upload',
    method: ApiMethod.post,
    requestType: RequestType.upload,
    filePath: '/path/to/image.jpg',
    fileField: 'avatar',
    body: {'user_id': '123'},
    onUploadProgress: (progress) {
      print('Upload: ${progress.sent}/${progress.total}');
    },
  ),
);

// Download a file
final downloadResponse = await apiClient.request(
  ApiRequest(
    endpoint: '/file.pdf',
    method: ApiMethod.get,
    requestType: RequestType.download,
    downloadSavePath: '/path/to/save/file.pdf',
    onDownloadProgress: (progress) {
      print('Download: ${progress.received}/${progress.total}');
    },
  ),
);
```

#### Custom Interceptors

Implement `ApiInterceptor` to hook into the request/response/error lifecycle:

```dart
class AuthInterceptor extends ApiInterceptor {
  @override
  Future<void> onRequest(RequestOptions options) async {
    options.headers['Authorization'] = 'Bearer $token';
  }

  @override
  Future<void> onError(DioException error) async {
    if (error.response?.statusCode == 401) {
      // refresh token logic
    }
  }
}

// Register
DioService.instance.addInterceptor(AuthInterceptor());
```

#### Logging with Print Control

The `NetworkLogger` only prints to the console when `printLogs` is `true`.

```dart
ApiConfig(
  baseUrl: 'https://api.example.com',
  printLogs: true, // ← enables console output
);
```

> The SDK `avoid_print` lint is expected – this is intentional. In production set `printLogs: false` to silence output.

---

### 2. Theming

#### AppThemeConfig

A single configuration object that controls **both** light and dark themes:

```dart
const AppThemeConfig(
  // ── Core colours ──────────────────────────────
  seedColor: Colors.indigo,
  useMaterial3: true,

  // ── Radii ─────────────────────────────────────
  borderRadius: 12,        // used for buttons, inputs, dialogs, chips
  cardRadius: 16,          // separate from border radius

  // ── Typography ────────────────────────────────
  fontFamily: 'Roboto',

  // ── Background / Surface colours ──────────────
  lightScaffoldColor: Color(0xFFF5F5F5),
  darkScaffoldColor: Color(0xFF121212),

  lightBackgroundColor: Color(0xFFFAFAFA),
  darkBackgroundColor: Color(0xFF1A1A2E),

  lightSurfaceColor: Colors.white,
  darkSurfaceColor: Color(0xFF1E1E1E),

  // ── Button overrides ──────────────────────────
  elevatedButtonElevation: 2,
  elevatedButtonTextStyle: TextStyle(fontWeight: FontWeight.w600),

  outlinedButtonSideWidth: 2.0,
  outlinedButtonSideColor: Color(0xFF3F51B5),
  outlinedButtonTextStyle: TextStyle(fontWeight: FontWeight.w600),

  textButtonTextStyle: TextStyle(fontWeight: FontWeight.w500),

  // ── Misc ──────────────────────────────────────
  iconThemeColor: Color(0xFF757575),
);
```

More options for the initial setup:

| Option | Effect |
|---|---|
| `initialThemeMode` | Theme mode on first launch, until the user picks one (default `ThemeMode.system`) |
| `lightColorScheme` / `darkColorScheme` | Exact colour schemes instead of the one generated from `seedColor` |
| `textTheme` | Merged over the default text theme |
| `visualDensity` | Compact or comfortable controls |
| `appBarCenterTitle` / `appBarElevation` | App bar title alignment (default centred) and elevation (default 0) |
| `inputFilled` | Filled text fields (default `true`) |
| `extensions` | Your own `ThemeExtension` design tokens, read with `Theme.of(context).extension<T>()` |
| `customize` | `(theme, brightness) => theme.copyWith(...)`, runs last on both themes for anything else |

`copyWith` makes variants of a config. Pass the config to `AppSetup.run` or `AppController.initialize` as `themeConfig`; `ServicesApp` applies it.

#### AppThemeManager

Generates fully‑wired `ThemeData` for light and dark modes:

```dart
MaterialApp(
  theme: AppThemeManager.lightTheme(myConfig),
  darkTheme: AppThemeManager.darkTheme(myConfig),
  themeMode: ThemeMode.system,
)
```

Both methods produce themes that include:

| Component              | What gets styled                                                                 |
|------------------------|----------------------------------------------------------------------------------|
| Scaffold               | `scaffoldBackgroundColor`                                                        |
| Canvas / card          | `canvasColor`, `cardColor` → from `light/darkBackgroundColor` / `surfaceColor`   |
| AppBar                 | Background from scaffold colour, transparent elevation, centred title            |
| Bottom navigation      | Background from surface colour, primary selected, 60% opacity unselected         |
| Card                   | Surface colour + 1px elevation + `effectiveCardRadius`                           |
| Elevated button        | `borderRadius`, `elevation`, `textStyle`                                         |
| Outlined button        | `borderRadius`, border `side` width/colour, `textStyle`                          |
| Text button            | `borderRadius`, `textStyle`                                                      |
| Icon                   | `iconThemeColor`                                                                 |
| Input decoration       | Filled, respective surface fill, `borderRadius`, enabled/focused borders          |
| Chip / Dialog          | `borderRadius` applied as shape                                                  |

#### AppThemeController

Holds the config, the `ThemeMode` and the user's accent colour, saves the choices to `SharedPreferences` and builds the themes:

```dart
final controller = AppThemeController.instance;

// Read current mode
print(controller.themeMode);    // ThemeMode.system

// Toggle between light / dark
controller.toggleTheme();

// Set specific mode
await controller.setThemeMode(ThemeMode.dark);

// User accent colour (saved); null returns to the config's seedColor
await controller.setSeedColor(Colors.pink);

// Switch the whole config at runtime, e.g. another brand
controller.setConfig(const AppThemeConfig(seedColor: Colors.green));

// Forget the saved mode and colour
await controller.resetToDefaults();

// Themes for the current config and colour, cached until something changes
controller.lightTheme;
controller.darkTheme;

// Listen for changes
controller.addListener(() {
  setState(() {});
});
```

#### Theme settings widgets

Drop-in controls for a settings screen, bound to `AppThemeController`:

```dart
const ThemeModeSelector();   // Light / System / Dark
const ThemeColorPicker();    // accent swatches, plus "Default"
ThemeColorPicker(colors: [Colors.indigo, Colors.teal, Colors.orange]);
const ThemeModeSwitcher();   // dark mode switch
```

#### Multi‑Button Theme Support

Because `AppThemeManager` provides dedicated `outlinedButtonTheme` and `textButtonTheme` (not just `elevatedButtonTheme`), **every** button variant picks up the correct styling automatically:

```dart
// These now respect borderRadius + textStyle defined in AppThemeConfig
ElevatedButton(onPressed: () {}, child: Text('Submit'));
OutlinedButton(onPressed: () {}, child: Text('Cancel'));
TextButton(onPressed: () {}, child: Text('Learn more'));
FilledButton(onPressed: () {}, child: Text('Save'));
```

---

### 3. Reusable Button Widget

#### AppButtonType Enum

```dart
enum AppButtonType {
  elevated,
  filled,
  outlined,
  text,
  tonal,
  icon,
  floatingAction,
  extendedFloatingAction,
  custom,            // ← fully customisable via builder
}
```

#### AppButtons Widget

A single widget that maps an `AppButtonType` to the correct Flutter widget:

```dart
// By type
AppButtons(
  type: AppButtonType.elevated,
  label: 'Submit',
  onPressed: _handleSubmit,
)

// With an icon
AppButtons(
  type: AppButtonType.elevated,
  label: 'Add',
  icon: const Icon(Icons.add),
  onPressed: _handleAdd,
)

// Disabled
AppButtons(
  type: AppButtonType.outlined,
  label: 'Cancel',
  isEnabled: false,
)
```

#### Named Factory Constructors

Each variant has a dedicated factory for cleaner code:

```dart
AppButtons.elevated(
  label: 'Submit',
  icon: Icon(Icons.send),
  onPressed: _handleSubmit,
);

AppButtons.filled(
  label: 'Save',
  onPressed: _handleSave,
);

AppButtons.outlined(
  label: 'Cancel',
  onPressed: _handleCancel,
);

AppButtons.text(
  label: 'Learn more',
  onPressed: _handleLearn,
);

AppButtons.tonal(
  label: 'Edit',
  onPressed: _handleEdit,
);

AppButtons.iconOnly(
  icon: Icon(Icons.favorite),
  onPressed: _handleLike,
);

AppButtons.fab(
  icon: Icon(Icons.add),
  onPressed: _handleAdd,
);

AppButtons.extendedFab(
  label: 'New Post',
  icon: Icon(Icons.edit),
  onPressed: _handleNewPost,
);
```

#### Custom / Extensibility

**Option A – `customBuilder`** (no subclassing needed):

```dart
AppButtons(
  type: AppButtonType.custom,
  label: '',   // unused for custom
  customBuilder: (context) {
    return GestureDetector(
      onTap: () => print('Custom tapped!'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text('Custom Button'),
      ),
    );
  },
);
```

**Option B – Subclass** (override any builder method):

```dart
class MyButtons extends AppButtons {
  const MyButtons({
    required super.type,
    required super.label,
    super.onPressed,
    super.key,
  });

  @override
  Widget _elevated() {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.star),
      label: Text(label),
    );
  }
}
```

**Option C – Extend the enum** by adding a new value and handling it in a wrapper.

---

### 4. Core Utilities

#### AppSetup and ServicesApp

`AppSetup.run` runs, in order: `WidgetsFlutterBinding.ensureInitialized()`, error handlers (when `onError` is given, framework and uncaught async errors go to it), `orientations` and `systemUiOverlayStyle`, `AppController.initialize`, `beforeRun`, then `runApp(app)`. If initialization or `beforeRun` throws, the error goes to `onError` and the app still starts; without `onError` it is rethrown.

```dart
Future<void> main() => AppSetup.run(
  features: const AppFeatures(sharedPref: true, theme: true, network: true),
  apiConfig: ApiConfig(baseUrl: 'https://api.example.com'),
  themeConfig: const AppThemeConfig(seedColor: Colors.indigo),
  beforeRun: () async => FormEnumRegistry.register('Plan', Plan.values),
  onError: (error, stack) => crashReporter.record(error, stack),
  app: const ServicesApp(title: 'Shop', home: HomePage()),
);
```

`ServicesApp` takes the usual `MaterialApp` options (`home`, `routes`, `onGenerateRoute`, `locale`, `localizationsDelegates`, `builder`, …) and `ServicesApp.router(routerConfig: ...)` works with go_router and other routers. Pass `theme`, `darkTheme` or `themeMode` to override the controller.

#### AppKeys

Global keys that `ServicesApp` attaches, for code without a `BuildContext`:

```dart
AppKeys.navigator?.pushNamed('/login');
AppKeys.messenger?.showSnackBar(const SnackBar(content: Text('Saved')));
showDialog(context: AppKeys.context!, builder: ...);
```

#### AppInitializer

Bootstraps shared preferences, theme, and networking in one call:

```dart
await AppInitializer.initialize(
  initializeSharedPref: true,
  initializeTheme: true,
  initializeNetwork: true,
  apiConfig: ApiConfig(baseUrl: 'https://api.example.com'),
);
```

#### SharedPrefManager

Persist / retrieve typed values:

```dart
// Save
await SharedPrefManager.saveData('username', 'john_doe');
await SharedPrefManager.saveData('score', 42);
await SharedPrefManager.saveData('isLoggedIn', true);

// Read
final name = SharedPrefManager.getData<String>('username');
final score = SharedPrefManager.getData<int>('score');
```

#### String and number extensions

Checks, conversions and formatting on `String`, `String?`, `double`, `double?` and `num` (number helpers work on both `double` and `int`):

```dart
'asha@example.com'.isEmail;            // true
'+91 98765-43210'.isPhone;             // true
'user_name'.toCamelCase();             // userName
'hello WORLD'.toTitleCase();           // Hello World
'Ranjit Kumar Makwana'.initials;       // RM
'9876543210'.mask();                   // ••••••3210
'Long product title'.truncate(10);     // Long prod…
nickname.or('Guest');                  // fallback when null or blank

3.14159.roundTo(2);                    // 3.14
2.50.toCleanString();                  // 2.5
1499.5.toCurrency('₹');                // ₹1,499.50
1234567.withSeparators(indian: true);  // 12,34,567
1250.toCompact();                      // 1.3K
150000.toCompact(indian: true);        // 1.5L
0.256.toPercent();                     // 26%

Column(children: [title, 8.heightBox, body]);
Container(padding: 16.allInsets);
```

Every member, with examples: [docs/extensions.md](docs/extensions.md). A test fails if a new extension member is not listed there.

#### Other Helpers

| File                   | Purpose                                           |
|------------------------|---------------------------------------------------|
| `app_logger.dart`      | Simple logger utility                             |
| `app_snackbar.dart`    | Show styled snackbars quickly                     |
| `app_dialogs.dart`     | Pre‑built dialog helpers                          |
| `app_responsive.dart`  | Responsive layout breakpoints                     |
| `app_validators.dart`  | Form validation helpers                           |
| `app_debouncer.dart`   | Debounce rapid events                             |
| `app_connectivity.dart`| Network connectivity checker                      |
| `app_extensions.dart`, `app_string_extensions.dart`, `app_number_extensions.dart` | `BuildContext`, `String` and number extensions ([reference](docs/extensions.md)) |
| `widgets/`             | `ServicesApp`, `AppScaffold`, `PrimaryLoader`, `ThemeModeSwitcher`, `ThemeModeSelector`, `ThemeColorPicker` |

---

### 5. Dynamic Forms

Build complete forms from JSON: 54 field types, validation (including one-key **text presets** for PAN, Aadhaar, GST, mobile, IFSC and more), conditional logic, multi-step wizards, edit mode, **searchable dropdowns** (local list or API, single or multiple), **radio and checkbox styles** (`card`, `chip`, `button`), **enum-driven options**, **extendable (repeatable) sections**, user-addable options, per-field styling and standard padding presets. Full reference: [docs/forms.md](docs/forms.md). Interactive guide with an element builder and search: [live form guide](https://mranjeethq.github.io/services_rj/). Demo app: [`example/`](example/).

A complete app. Paste it into `lib/main.dart` and run it. `DynamicForm` is a scrolling list, so it goes in a `Scaffold` body:

```dart
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

enum MealChoice { vegetarian, vegan, nonVegetarian }

void main() {
  FormEnumRegistry.register('MealChoice', MealChoice.values);
  // Search-as-you-type source. Replace the body with your API call.
  FormSearchSources.register('venues', (query, formData) async {
    const venues = ['Riverside Hall', 'Rooftop Garden', 'Old Library'];
    return [
      for (final v in venues)
        if (v.toLowerCase().contains(query.toLowerCase()))
          OptionItem(label: v, value: v),
    ];
  });
  runApp(const MaterialApp(home: RsvpPage()));
}

const rsvpForm = {
  'padding': 'standard',
  'fields': [
    {
      'type': 'text',
      'id': 'name',
      'label': 'Your name',
      'validators': ['required'],
    },
    {
      'type': 'searchableDropdown', // searches the 'venues' source
      'id': 'venue',
      'label': 'Venue',
      'searchSource': 'venues',
    },
    {
      'type': 'repeater', // extendable section
      'id': 'guests',
      'itemLabel': 'Guest {index}',
      'addLabel': 'Add another guest',
      'minItems': 1,
      'maxItems': 4,
      'fields': [
        {'type': 'text', 'id': 'guestName', 'label': 'Guest name'},
        {
          'type': 'dropdown',
          'id': 'meal',
          'label': 'Meal',
          'enum': 'MealChoice',
        },
      ],
    },
    {
      'type': 'searchableDropdown',
      'id': 'topics',
      'label': 'Topics you like',
      'multiple': true, // value is a List
      'allowCustomOptions': true, // users can add their own
      'options': ['Web', 'Testing', 'Design'],
    },
    {
      'type': 'radioGroup',
      'id': 'seating',
      'label': 'Seating',
      'optionStyle': 'button', // standard | card | chip | button
      'options': ['Front', 'Middle', 'Back'],
      'style': {'activeColor': '#00897B'},
    },
  ],
};

class RsvpPage extends StatefulWidget {
  const RsvpPage({super.key});

  @override
  State<RsvpPage> createState() => _RsvpPageState();
}

class _RsvpPageState extends State<RsvpPage> {
  final controller = DynamicFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RSVP')),
      body: DynamicForm(
        controller: controller,
        json: rsvpForm,
        showSubmitButton: true,
        // guests -> List<Map>, topics -> List, seating -> 'Front'
        onSubmit: (data) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('RSVP: $data'))),
      ),
    );
  }
}
```

Read values back and drive the form from code:

```dart
controller.getFormData();                       // {name: ..., venue: ..., guests: [...], ...}
controller.validate();                          // true when valid; errors show on screen
controller.getEnum('meal', MealChoice.values);  // typed read-back
controller.setValue('seating', 'Front');
controller.addEntry('guests', data: {'guestName': 'Asha'});
```

Searchable dropdown options can come from a local `options` list, an API loaded once (`DynamicFormController(optionsLoader: ...)`), or an API searched as the user types (`"searchSource"` + `FormSearchSources.register`). See [Searchable dropdown](docs/forms.md#searchable-dropdown).

> The form engine is based on [json_form_engine](https://github.com/rupeshrajak0285/json_form_engine) by Rupesh Rajak (MIT). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

### 6. AppController, caching and encryption

`AppController.initialize(...)` starts only the features you enable and exposes them through `AppController.instance`.

| Feature | What it controls |
|---|---|
| `sharedPref` | `SharedPrefManager` |
| `theme` | `AppThemeController` |
| `network` | `DioService`, `ApiClient` (needs an `ApiConfig`) |
| `apiCache` | Memory and disk response cache |
| `encryption` | AES-256-GCM for preferences and cache files |
| `connectivity` | Online and offline tracking |
| `logger` / `networkLogs` | `AppLogger` and request / response logs |
| `permissions` | `AppPermissionManager` |

```dart
await AppController.initialize(
  features: const AppFeatures(
    sharedPref: true,
    theme: true,
    network: true,
    apiCache: true,
    encryption: true,
  ),
  apiConfig: ApiConfig(baseUrl: 'https://api.example.com'),
);

final app = AppController.instance;
await app.setEnabled(AppFeature.logger, false); // runtime switch
```

- **Caching**: GET responses are cached with stale-while-revalidate by default (`networkFirst`, `cacheFirst`, `cacheOnly` and `networkOnly` are available), served instantly when offline, shared between identical requests and invalidated after mutations.
- **Encryption**: the 256-bit key lives in the Keychain or Keystore, preferences and cache files are encrypted, and tampered data is discarded.

Details: [docs/app_controller.md](docs/app_controller.md).

---

### 7. Permissions

A queued `AppPermissionManager` on top of `permission_handler`, with per-platform and per-Android-version mapping and an `ensure()` flow that explains, asks and offers settings.

```dart
await AppController.initialize(
  features: const AppFeatures(permissions: true),
);

final status = await AppPermissionManager.instance.request(AppPermission.camera);
if (status.isUsable) openCamera();
```

Platform setup and the full permission list: [docs/permissions.md](docs/permissions.md).

---

## Example

The [example app](example/) has a page for every feature: run `cd example && flutter run`. Highlights for a new project: **App setup** (`AppSetup.run`, `ServicesApp`, `AppKeys`, a theme settings screen), **Theme** (every `AppThemeConfig` option with live previews and "Apply to whole app"), and **Extensions** (every string and number extension on live input). See [example/README.md](example/README.md).

A small complete app:

```dart
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

Future<void> main() => AppSetup.run(
  features: const AppFeatures(
    sharedPref: true,
    theme: true,
    network: true,
    logger: true,
  ),
  apiConfig: ApiConfig(baseUrl: 'https://jsonplaceholder.typicode.com'),
  themeConfig: const AppThemeConfig(
    seedColor: Colors.teal,
    borderRadius: 14,
    cardRadius: 20,
    outlinedButtonSideWidth: 2,
  ),
  onError: (error, stack) => AppLogger.error('$error', stackTrace: stack),
  app: const ServicesApp(title: 'services_rj demo', home: HomePage()),
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _fetch() async {
    final res = await ApiClient.instance.request(
      ApiRequest(endpoint: '/posts/1', method: ApiMethod.get),
    );
    final title = '${(res.data as Map)['title']}';
    // No BuildContext needed: ServicesApp attached AppKeys.
    AppKeys.messenger?.showSnackBar(
      SnackBar(content: Text(title.toTitleCase().truncate(40))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('services_rj')),
      body: ListView(
        padding: 16.allInsets,
        children: [
          const ThemeModeSelector(),
          16.heightBox,
          const ThemeColorPicker(),
          24.heightBox,
          Text('Total: ${1249999.5.toCurrency('₹', indian: true)}'),
          Text('Views: ${1250.toCompact()}'),
          16.heightBox,
          AppButtons.elevated(label: 'Fetch post', onPressed: _fetch),
          12.heightBox,
          AppButtons.outlined(label: 'Outlined', onPressed: () {}),
        ],
      ),
      floatingActionButton: AppButtons.fab(
        icon: const Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }
}
```

---

## Additional Information

- **License**: MIT, © 2026 Ranjit Makwana (see [LICENSE](LICENSE)). The form engine is based on MIT-licensed code by Rupesh Rajak, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
- **Issues**: [github.com/MranjeetHQ/services_rj/issues](https://github.com/MranjeetHQ/services_rj/issues)
- **Contributions**: PRs are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md)
- **Security**: report vulnerabilities privately, see [SECURITY.md](SECURITY.md)
- **Maintainer**: Ranjit Makwana · [LinkedIn](https://www.linkedin.com/in/makwanaranjit33/) · [GitHub](https://github.com/MranjeetHQ)
- **Release notes**: [RELEASE_NOTES.md](RELEASE_NOTES.md) · [CHANGELOG.md](CHANGELOG.md)
