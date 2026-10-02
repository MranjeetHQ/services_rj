import 'package:flutter/material.dart';

class AppDialogs {
  AppDialogs._();

  static Future<void> showLoading(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  static Future<void> showMessage(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(title: Text(title), content: Text(message));
      },
    );
  }
}
