import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettingsService _settingsService = AppSettingsService.instance;

  bool _loading = true;
  bool _saving = false;

  AppSettings _saved = AppSettings.defaults;
  AppSettings _draft = AppSettings.defaults;

  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      final loaded = await _settingsService.load();
      if (!mounted) return;
      setState(() {
        _saved = loaded;
        _draft = loaded;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  bool get _isDirty {
    return _saved.bookingAlerts != _draft.bookingAlerts ||
        _saved.soundAlerts != _draft.soundAlerts ||
        _saved.weeklySummary != _draft.weeklySummary;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });

    try {
      await _settingsService.save(_draft);
      if (!mounted) return;

      setState(() {
        _saved = _draft;
        _message = 'Settings saved successfully';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _resetDraft() {
    setState(() {
      _draft = _saved;
      _message = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Manage your notification and app preferences.'),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F9EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7E3B8)),
            ),
            child: Text(
              _message!,
              style: const TextStyle(color: Color(0xFF166534)),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  value: _draft.bookingAlerts,
                  title: const Text('Booking alerts'),
                  subtitle: const Text('Show new booking and update banners.'),
                  onChanged: (value) => setState(() => _draft = _draft.copyWith(bookingAlerts: value)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _draft.soundAlerts,
                  title: const Text('Sound on new notification'),
                  subtitle: const Text('Play a short beep for new notifications.'),
                  onChanged: (value) => setState(() => _draft = _draft.copyWith(soundAlerts: value)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _draft.weeklySummary,
                  title: const Text('Weekly performance summary'),
                  subtitle: const Text('Receive a weekly earnings summary reminder.'),
                  onChanged: (value) => setState(() => _draft = _draft.copyWith(weeklySummary: value)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: (_saving || !_isDirty) ? null : _resetDraft,
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: (_saving || !_isDirty) ? null : _saveSettings,
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save Settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portal notes', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                const Text('These preferences are saved locally on this device and are retained across app restarts.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
