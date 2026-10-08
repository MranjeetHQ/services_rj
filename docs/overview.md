# services_rj

A lightweight yet scalable Flutter utility package providing:

- Smart SharedPreferences management
- Dynamic Theme Management
- Responsive utilities
- Snackbar & Dialog helpers
- Validators
- Debouncer
- Connectivity helpers
- Reusable widgets
- Developer-friendly extensions

Designed for production-ready Flutter applications with minimal setup and maximum scalability.

---

# Features

✅ Persistent Theme Management  
✅ Light / Dark / System Theme Support  
✅ SharedPreferences Wrapper  
✅ Material 3 Support  
✅ Global Theme Configuration  
✅ Responsive Helpers  
✅ Snackbar Utilities  
✅ Dialog Utilities  
✅ Form Validators  
✅ Connectivity Helpers  
✅ Debouncer Utility  
✅ Reusable Widgets  
✅ Easy Initialization  
✅ Minimal Boilerplate  
✅ Scalable Architecture  

---

# Installation

Add dependency in `pubspec.yaml`

```yaml
dependencies:
  services_rj: latest_version
```

Then run:

```bash
flutter pub get
```

---

# Initialize Package

```dart
Future<void> main() => AppSetup.run(
  features: const AppFeatures(sharedPref: true, theme: true),
  themeConfig: const AppThemeConfig(
    seedColor: Colors.deepPurple,
    borderRadius: 16,
  ),
  app: const ServicesApp(home: HomePage()),
);
```

`ServicesApp` is a `MaterialApp` that applies the theme config, the saved theme mode and the user's accent colour, and rebuilds when they change. The full setup is in the README and [FEATURES.md](../FEATURES.md).

---

# Theme Management

## Toggle Theme

```dart
AppThemeController.instance.toggleTheme();
```

## Set Specific Theme

```dart
AppThemeController.instance.setThemeMode(
  ThemeMode.dark,
);
```

---

# Theme Configuration

```dart
const config = AppThemeConfig(
  seedColor: Colors.deepPurple,
  borderRadius: 20,
  useMaterial3: true,
);
```

## Available Configurations

| Property | Description |
|----------|-------------|
| seedColor | Primary application color |
| borderRadius | Global border radius |
| useMaterial3 | Enable Material 3 |
| fontFamily | Global font family |
| lightScaffoldColor | Scaffold color for light mode |
| darkScaffoldColor | Scaffold color for dark mode |
| initialThemeMode | Theme mode on first launch |
| lightColorScheme / darkColorScheme | Exact colour schemes instead of the seed |
| customize | Hook to change anything else on the generated themes |

## Theme Settings Widgets

```dart
const ThemeModeSelector()   // Light / System / Dark
const ThemeColorPicker()    // accent colour, saved
```

---

# Shared Preference Manager

## Save Data

```dart
await SharedPrefManager.saveData(
  'token',
  'abc123',
);
```

## Get Data

```dart
final token =
    SharedPrefManager.getData<String>(
  'token',
);
```

## Delete Data

```dart
await SharedPrefManager.delete(
  'token',
);
```

---

# Snackbar Utility

## Success Snackbar

```dart
AppSnackbar.success(
  context,
  'Login Successful',
);
```

## Error Snackbar

```dart
AppSnackbar.error(
  context,
  'Something went wrong',
);
```

---

# Dialog Utility

## Show Loading

```dart
await AppDialogs.showLoading(
  context,
);
```

## Show Message

```dart
await AppDialogs.showMessage(
  context,
  title: 'Success',
  message: 'Profile Updated',
);
```

---

# Validators

## Email Validator

```dart
validator: AppValidators.email,
```

## Password Validator

```dart
validator: AppValidators.password,
```

## Required Field Validator

```dart
validator: AppValidators.requiredField,
```

---

# Responsive Helpers

```dart
AppResponsive.isMobile(context)

AppResponsive.isTablet(context)

AppResponsive.isDesktop(context)
```

---

# Extensions

```dart
context.theme
context.colors
context.isDarkMode

'user_name'.toCamelCase()     // userName
'9876543210'.mask()           // ••••••3210
name.or('Guest')

3.14159.roundTo(2)            // 3.14
1499.5.toCurrency('₹')        // ₹1,499.50
1250.toCompact()              // 1.3K
16.heightBox                  // SizedBox(height: 16)
```

Full list: [extensions.md](extensions.md).

---

# Debouncer

```dart
final debouncer = AppDebouncer();

debouncer.run(() {
  print('Search API Call');
});
```

---

# Connectivity

## Check Internet

```dart
final hasInternet =
    await AppConnectivity.hasInternet();
```

## Listen Connectivity

```dart
AppConnectivity.stream.listen((event) {
  print(event);
});
```

---

# Widgets

## ThemeModeSwitcher

```dart
const ThemeModeSwitcher()
```

## PrimaryLoader

```dart
const PrimaryLoader()
```

## AppScaffold

```dart
AppScaffold(
  body: YourWidget(),
)
```

---

# Architecture

```text
lib/
 ├── services_rj.dart
 │
 └── src
      ├── core
      │    ├── shared_pref_manager.dart
      │    ├── app_theme_manager.dart
      │    ├── app_theme_config.dart
      │    ├── app_theme_controller.dart
      │    ├── app_extensions.dart
      │    ├── app_dialogs.dart
      │    ├── app_snackbar.dart
      │    ├── app_logger.dart
      │    ├── app_responsive.dart
      │    ├── app_validators.dart
      │    ├── app_debouncer.dart
      │    ├── app_connectivity.dart
      │    └── app_initializer.dart
      │
      └── widgets
           ├── theme_mode_switcher.dart
           ├── primary_loader.dart
           └── app_scaffold.dart
```

---

# Philosophy

`services_rj` is built with the following principles:

- Minimal Boilerplate
- Production Ready
- Highly Scalable
- Clean APIs
- Modular Architecture
- Developer Friendly
- Ecosystem Compatible
- Easy Maintenance

---

# Future Roadmap

The current feature list and the prioritized roadmap are kept in [FEATURES.md](../FEATURES.md).

---

# Contributing

Contributions are welcome.

Feel free to open issues and pull requests.

---

# License

MIT License