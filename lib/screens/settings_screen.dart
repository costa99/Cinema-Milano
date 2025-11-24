import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeController themeController;

  const SettingsScreen({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListenableBuilder(
            listenable: themeController,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RadioListTile<AppTheme>(
                    title: const Text('System Default'),
                    value: AppTheme.system,
                    groupValue: themeController.appTheme,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        themeController.setTheme(value);
                      }
                    },
                  ),
                  RadioListTile<AppTheme>(
                    title: const Text('Light Theme'),
                    value: AppTheme.light,
                    groupValue: themeController.appTheme,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        themeController.setTheme(value);
                      }
                    },
                  ),
                  RadioListTile<AppTheme>(
                    title: const Text('Dark Theme'),
                    value: AppTheme.dark,
                    groupValue: themeController.appTheme,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        themeController.setTheme(value);
                      }
                    },
                  ),
                  RadioListTile<AppTheme>(
                    title: const Text('Neon Theme'),
                    value: AppTheme.neon,
                    groupValue: themeController.appTheme,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        themeController.setTheme(value);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
