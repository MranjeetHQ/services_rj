# services_rj

A Flutter utility package that provides out‑of‑the‑box support for **networking** with **offline caching**, **encrypted storage**, **runtime permissions**, **JSON-driven dynamic forms**, **theming**, **button widgets**, **shared preferences**, and common app‑level helpers. One `AppController` switches every feature on or off.

**Guides:** [AppController, caching and encryption](docs/app_controller.md) · [Permissions](docs/permissions.md) · [Dynamic forms](docs/forms.md) · [Form guide website](form_guide_web/) (with an element builder) · [Release notes](RELEASE_NOTES.md) · [QA report](docs/qa_report.md)

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
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
    - [Multi‑Button Theme Support](#multi-button-theme-support)
  - [3. Reusable Button Widget](#3-reusable-button-widget)
    - [AppButtonType Enum](#appbuttontype-enum)
    - [Named Factory Constructors](#named-factory-constructors)
    - [Custom / Extensibility](#custom--extensibility)
  - [4. Core Utilities](#4-core-utilities)
    - [AppInitializer](#appinitializer)
    - [SharedPrefManager](#sharedprefmanager)
    - [Other Helpers](#other-helpers)
  - [5. Dynamic Forms](#5-dynamic-forms)
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

```dart
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Features are opt-in. This app uses preferences and theme state.
  await AppController.initialize(
    features: const AppFeatures(sharedPref: true, theme: true),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'services_rj Demo',
      theme: AppThemeManager.lightTheme(
        const AppThemeConfig(
          seedColor: Colors.teal,
          borderRadius: 12,
          cardRadius: 16,
          lightScaffoldColor: Color(0xFFF5F5F5),
          lightSurfaceColor: Colors.white,
          outlinedButtonSideWidth: 2.0,
          outlinedButtonSideColor: Colors.teal,
        ),
      ),
      darkTheme: AppThemeManager.darkTheme(
        const AppThemeConfig(
          seedColor: Colors.teal,
          borderRadius: 12,
          cardRadius: 16,
          darkScaffoldColor: Color(0xFF121212),
          darkSurfaceColor: Color(0xFF1E1E1E),
        ),
      ),
      themeMode: AppThemeController.instance.themeMode,
      home: const HomeScreen(),
    );
  }
}
```

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

Manages the `ThemeMode` and persists the user's choice to `SharedPreferences`:

```dart
final controller = AppThemeController.instance;

// Read current mode
print(controller.themeMode);    // ThemeMode.system

// Toggle between light / dark
controller.toggleTheme();

// Set specific mode
await controller.setThemeMode(ThemeMode.dark);

// Listen for changes
controller.addListener(() {
  setState(() {});
});
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
| `app_extensions.dart`  | Common Dart / Flutter extensions                  |
| `widgets/`             | `AppScaffold`, `PrimaryLoader`, `ThemeModeSwitcher` |

---

### 5. Dynamic Forms

Build complete forms from JSON — 53 field types, validation (including one-key **text presets** for PAN, Aadhaar, GST, mobile, IFSC and more), conditional logic, multi-step wizards, edit mode, **enum-driven options**, **extendable (repeatable) sections**, user-addable options and per-field styling. Full reference: [docs/forms.md](docs/forms.md). Interactive guide: [`form_guide_web/`](form_guide_web/). Demo app: [`example/`](example/).

```dart
enum MealChoice { vegetarian, vegan, nonVegetarian }

void main() {
  FormEnumRegistry.register('MealChoice', MealChoice.values);
  runApp(const MyApp());
}

const rsvpJson = {
  'fields': [
    {'type': 'text', 'id': 'name', 'label': 'Your name', 'validators': ['required']},
    {
      'type': 'repeater',                 // extendable section
      'id': 'guests',
      'itemLabel': 'Guest {index}',
      'addLabel': 'Add another guest',
      'minItems': 1,
      'maxItems': 4,
      'fields': [
        {'type': 'text', 'id': 'guestName', 'label': 'Guest name', 'required': true},
        {'type': 'dropdown', 'id': 'meal', 'label': 'Meal', 'enum': 'MealChoice'},
      ],
    },
    {
      'type': 'chips',
      'id': 'topics',
      'multiple': true,
      'allowCustomOptions': true,         // users can add their own
      'options': ['Web', 'Testing'],
      'style': {'activeColor': '#00897B'},
    },
  ],
};

DynamicForm(
  controller: controller,               // DynamicFormController
  json: rsvpJson,
  showSubmitButton: true,
  onSubmit: (data) => api.save(data),   // guests → List<Map>, meal → 'vegan'
  fieldOverrides: {
    'name': FieldOverrides(wrapper: (context, field, child) => Card(child: child)),
  },
);

controller.getEnum('meal', MealChoice.values);  // typed read-back
controller.addEntry('guests', data: {'guestName': 'Asha'});
```

> The form engine is based on [json_form_engine](https://github.com/rupeshrajak0285/json_form_engine) by Rupesh Rajak (MIT). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

## Example

A complete app demonstrating all the features:

```dart
import 'package:flutter/material.dart';
import 'package:services_rj/services_rj.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInitializer.initialize(
    initializeSharedPref: true,
    initializeTheme: true,
    initializeNetwork: true,
    apiConfig: ApiConfig(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      printLogs: true,
      connectTimeout: 10000,
    ),
  );

  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const config = AppThemeConfig(
      seedColor: Colors.teal,
      borderRadius: 14,
      cardRadius: 20,
      lightScaffoldColor: Color(0xFFF9F9F9),
      darkScaffoldColor: Color(0xFF121212),
      lightSurfaceColor: Colors.white,
      darkSurfaceColor: Color(0xFF1E1E1E),
      elevatedButtonElevation: 3,
      outlinedButtonSideWidth: 2,
      outlinedButtonSideColor: Colors.teal,
    );

    return MaterialApp(
      title: 'services_rj Demo',
      theme: AppThemeManager.lightTheme(config),
      darkTheme: AppThemeManager.darkTheme(config),
      themeMode: AppThemeController.instance.themeMode,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('services_rj')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButtons.elevated(
              label: 'Elevated Button',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            AppButtons.outlined(
              label: 'Outlined Button',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            AppButtons.text(
              label: 'Text Button',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            AppButtons.filled(
              label: 'Filled Button',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            AppButtons(
              type: AppButtonType.custom,
              label: '',
              customBuilder: (ctx) => ElevatedButton.icon(
                onPressed: () async {
                  final res = await ApiClient.instance.request(
                    ApiRequest(
                      endpoint: '/posts/1',
                      method: ApiMethod.get,
                    ),
                  );
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('${res.statusCode} — ${res.data}')),
                    );
                  }
                },
                icon: const Icon(Icons.cloud_download),
                label: const Text('Fetch Post'),
              ),
            ),
          ],
        ),
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

- **License**: MIT (see `LICENSE` file)
- **Issues**: file them on the project's issue tracker
- **Contributions**: PRs are welcome – please follow the existing code style and include tests where appropriate
- **Maintainer**: [Author / Organisation name]