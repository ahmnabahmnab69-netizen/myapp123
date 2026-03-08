import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _focusMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusMode = prefs.getBool('focusMode') ?? false;
    });
  }

  Future<void> _toggleFocusMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('focusMode', value);
    setState(() {
      _focusMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Focus Mode', style: theme.textTheme.bodyMedium),
              subtitle: Text('Discourage switching apps during tasks', style: theme.textTheme.bodySmall),
              value: _focusMode,
              onChanged: _toggleFocusMode,
              activeTrackColor: theme.colorScheme.primary.withAlpha(150),
              thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return theme.colorScheme.primary;
                }
                return null;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
