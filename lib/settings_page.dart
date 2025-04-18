// settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Karanlık Tema'),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
            const SizedBox(height: 20),
            Text('Yazı Boyutu: ${themeProvider.fontSize.toInt()}'),
            Slider(
              value: themeProvider.fontSize,
              min: 12,
              max: 24,
              divisions: 6,
              label: themeProvider.fontSize.toInt().toString(),
              onChanged: (val) => themeProvider.updateFontSize(val),
            ),
            const SizedBox(height: 20),
            const Text('Uygulama Versiyonu: 1.0.0'),
          ],
        ),
      ),
    );
  }
}
