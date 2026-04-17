import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.bookingAlerts,
    required this.soundAlerts,
    required this.weeklySummary,
  });

  final bool bookingAlerts;
  final bool soundAlerts;
  final bool weeklySummary;

  Map<String, dynamic> toJson() {
    return {
      'bookingAlerts': bookingAlerts,
      'soundAlerts': soundAlerts,
      'weeklySummary': weeklySummary,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> value) {
    return AppSettings(
      bookingAlerts: value['bookingAlerts'] == true,
      soundAlerts: value['soundAlerts'] == true,
      weeklySummary: value['weeklySummary'] == true,
    );
  }

  AppSettings copyWith({
    bool? bookingAlerts,
    bool? soundAlerts,
    bool? weeklySummary,
  }) {
    return AppSettings(
      bookingAlerts: bookingAlerts ?? this.bookingAlerts,
      soundAlerts: soundAlerts ?? this.soundAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }

  static const defaults = AppSettings(
    bookingAlerts: true,
    soundAlerts: true,
    weeklySummary: false,
  );
}

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const String _storageKey = 'fixitpro_provider_settings';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings.defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppSettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_error) {
      // Ignore malformed storage values and continue with defaults.
    }

    return AppSettings.defaults;
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(settings.toJson()));
  }
}
