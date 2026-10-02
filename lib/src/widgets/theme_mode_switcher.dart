import 'package:flutter/material.dart';

import '../core/app_theme_controller.dart';

class ThemeModeSwitcher extends StatelessWidget {
  const ThemeModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (_, _) {
        return Switch(
          value: AppThemeController.instance.isDarkMode,
          onChanged: (_) {
            AppThemeController.instance.toggleTheme();
          },
        );
      },
    );
  }
}
