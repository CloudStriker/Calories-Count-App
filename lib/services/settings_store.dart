import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String defaultGeminiModel = 'gemini-3.5-flash-lite';
const int defaultDailyCalorieGoal = 2000;

const List<String> presetGeminiModels = <String>[
  'gemini-3.5-flash-lite',
  'gemini-3.8-flash',
  'gemini-3.1-flash-lite',
];

class AppSettings {
  const AppSettings({
    this.apiKey,
    this.modelName = defaultGeminiModel,
    this.dailyCalorieGoal = defaultDailyCalorieGoal,
  });

  final String? apiKey;
  final String modelName;
  final int dailyCalorieGoal;

  bool get hasApiKey => apiKey != null && apiKey!.trim().isNotEmpty;

  AppSettings copyWith({
    String? apiKey,
    bool clearApiKey = false,
    String? modelName,
    int? dailyCalorieGoal,
  }) {
    return AppSettings(
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      modelName: modelName ?? this.modelName,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
    );
  }
}

abstract class SettingsStore {
  Future<AppSettings> load();
  Future<void> saveApiKey(String apiKey);
  Future<void> clearApiKey();
  Future<void> saveModelName(String modelName);
  Future<void> saveDailyCalorieGoal(int goal);
}

class DeviceSettingsStore implements SettingsStore {
  DeviceSettingsStore({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? prefsLoader,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            ),
        _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  static const String _apiKeyStorageKey = 'gemini_api_key';
  static const String _modelPrefKey = 'gemini_model';
  static const String _goalPrefKey = 'daily_calorie_goal';

  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _prefsLoader;

  @override
  Future<AppSettings> load() async {
    final prefs = await _prefsLoader();
    String? storedKey;
    try {
      storedKey = await _secureStorage.read(key: _apiKeyStorageKey);
    } catch (_) {
      storedKey = null;
    }

    final rawModel = prefs.getString(_modelPrefKey)?.trim();
    final modelName = (rawModel == null || rawModel.isEmpty)
        ? defaultGeminiModel
        : rawModel;

    final rawGoal = prefs.getInt(_goalPrefKey) ?? defaultDailyCalorieGoal;
    final safeGoal =
        (rawGoal >= 500 && rawGoal <= 10000) ? rawGoal : defaultDailyCalorieGoal;

    return AppSettings(
      apiKey: storedKey?.trim().isEmpty == true ? null : storedKey?.trim(),
      modelName: modelName,
      dailyCalorieGoal: safeGoal,
    );
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await clearApiKey();
      return;
    }
    await _secureStorage.write(key: _apiKeyStorageKey, value: trimmed);
  }

  @override
  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  @override
  Future<void> saveModelName(String modelName) async {
    final prefs = await _prefsLoader();
    final trimmed = modelName.trim();
    await prefs.setString(
      _modelPrefKey,
      trimmed.isEmpty ? defaultGeminiModel : trimmed,
    );
  }

  @override
  Future<void> saveDailyCalorieGoal(int goal) async {
    final prefs = await _prefsLoader();
    final clamped = goal.clamp(500, 10000);
    await prefs.setInt(_goalPrefKey, clamped);
  }
}
