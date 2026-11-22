import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/services/food_analyzer.dart';
import 'package:calsnap/services/health_sync_service.dart';
import 'package:calsnap/services/meal_database.dart';
import 'package:calsnap/services/photo_storage.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:flutter/foundation.dart';

class MealLogController extends ChangeNotifier {
  MealLogController({
    required this._settingsStore,
    required this._mealStore,
    required this._photoStore,
    required this._foodAnalyzer,
    required this._healthSync,
    DateTime? initialDate,
  }) : _selectedDate = startOfDay(initialDate ?? DateTime.now());

  final SettingsStore _settingsStore;
  final MealStore _mealStore;
  final PhotoStore _photoStore;
  final FoodAnalyzer _foodAnalyzer;
  final HealthSyncGateway _healthSync;

  DateTime _selectedDate;
  List<MealEntry> _meals = const <MealEntry>[];
  Map<DateTime, double> _weeklyCalories = const <DateTime, double>{};
  AppSettings _settings = const AppSettings();
  HealthAvailability _healthAvailability = HealthAvailability.unavailable;
  bool _hasHealthPermission = false;
  HealthConnectDaySummary? _todayHealthSummary;
  bool _isLoading = false;
  String? _errorMessage;
  int _idCounter = 0;

  DateTime get selectedDate => _selectedDate;
  List<MealEntry> get meals => _meals;
  Map<DateTime, double> get weeklyCalories => _weeklyCalories;
  AppSettings get settings => _settings;
  HealthAvailability get healthAvailability => _healthAvailability;
  bool get hasHealthPermission => _hasHealthPermission;
  HealthConnectDaySummary? get todayHealthSummary => _todayHealthSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DailyTotals get dailyTotals => DailyTotals.fromMeals(_meals);

  Future<Map<DateTime, double>> _fetchWeeklyCalories() async {
    final days = buildWeekWindow(_selectedDate);
    final totals = await _mealStore.getDailyCaloriesInRange(
      days.first,
      days.last,
    );
    return Map<DateTime, double>.unmodifiable(totals);
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        _settingsStore.load(),
        _mealStore.getMealsForDate(_selectedDate),
        _fetchWeeklyCalories(),
        _loadHealthStatus(),
      ]);
      _settings = results[0]! as AppSettings;
      _meals = List<MealEntry>.unmodifiable(results[1]! as List<MealEntry>);
      _weeklyCalories = results[2]! as Map<DateTime, double>;
    } catch (_) {
      _errorMessage = 'Gagal memuat data harian.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = startOfDay(date);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        _mealStore.getMealsForDate(_selectedDate),
        _fetchWeeklyCalories(),
      ]);
      _meals = List<MealEntry>.unmodifiable(results[0]! as List<MealEntry>);
      _weeklyCalories = results[1]! as Map<DateTime, double>;
    } catch (_) {
      _errorMessage = 'Gagal memuat riwayat tanggal ini.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHealthStatus() async {
    await _loadHealthStatus();
    notifyListeners();
  }

  Future<void> _loadHealthStatus() async {
    final availability = await _healthSync.checkAvailability();
    final permitted = availability == HealthAvailability.available
        ? await _healthSync.hasWritePermission()
        : false;
    _healthAvailability = availability;
    _hasHealthPermission = permitted;
    _todayHealthSummary = (availability == HealthAvailability.available &&
            permitted)
        ? await _healthSync.readTodaySyncedSummary(DateTime.now())
        : null;
  }

  Future<bool> connectHealthConnect() async {
    final availability = await _healthSync.checkAvailability();
    _healthAvailability = availability;
    if (availability == HealthAvailability.needsInstall) {
      await _healthSync.installHealthConnect();
      notifyListeners();
      return false;
    }
    if (availability == HealthAvailability.unavailable) {
      _hasHealthPermission = false;
      _todayHealthSummary = null;
      notifyListeners();
      return false;
    }
    final granted = await _healthSync.requestWritePermission();
    _hasHealthPermission = granted;
    _todayHealthSummary = granted
        ? await _healthSync.readTodaySyncedSummary(DateTime.now())
        : null;
    notifyListeners();
    return granted;
  }

  Future<bool> openHealthConnectSettings() =>
      _healthSync.openHealthConnectSettings();

  Future<FoodAnalysisResult> analyzePhoto({
    required Uint8List imageBytes,
    required String mimeType,
    String? userNote,
  }) {
    return _foodAnalyzer.analyze(
      imageBytes: imageBytes,
      mimeType: mimeType,
      userNote: userNote,
    );
  }

  Future<MealEntry> saveMeal({
    required DateTime eatenAt,
    required MealCategory category,
    required String title,
    required List<FoodItem> items,
    Uint8List? photoBytes,
    String? userNote,
  }) async {
    _idCounter += 1;
    final mealId = '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
    String? savedPhotoPath;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      savedPhotoPath = await _photoStore.saveMealPhoto(photoBytes, mealId);
    }

    final entry = MealEntry.fromItems(
      id: mealId,
      eatenAt: eatenAt,
      category: category,
      title: title,
      photoPath: savedPhotoPath,
      userNote: userNote?.trim().isEmpty == true ? null : userNote?.trim(),
      items: items,
      syncStatus: HealthSyncStatus.pending,
    );

    // Persist locally first so meal records are never lost if Health Connect fails.
    await _mealStore.insertMeal(entry);
    return _syncAndReload(entry);
  }

  Future<MealEntry> retryHealthSync(MealEntry meal) => _syncAndReload(meal);

  Future<MealEntry> _syncAndReload(MealEntry meal) async {
    final syncResult = await _healthSync.writeMeal(meal);
    await _mealStore.updateSyncStatus(
      mealId: meal.id,
      status: syncResult.status,
      error: syncResult.errorMessage,
      recordId: syncResult.recordId,
    );
    final updated = meal.copyWith(
      syncStatus: syncResult.status,
      syncError: syncResult.errorMessage,
      clearSyncError: syncResult.errorMessage == null,
      healthRecordId: syncResult.recordId,
    );
    await _loadHealthStatus();
    if (isSameDay(meal.eatenAt, _selectedDate)) {
      final reloaded = await _mealStore.getMealsForDate(_selectedDate);
      _meals = List<MealEntry>.unmodifiable(reloaded);
    }
    _weeklyCalories = await _fetchWeeklyCalories();
    notifyListeners();
    return updated;
  }

  Future<void> deleteMeal(MealEntry meal) async {
    await _mealStore.deleteMeal(meal.id);
    await _photoStore.deleteMealPhoto(meal.photoPath);
    if (isSameDay(meal.eatenAt, _selectedDate)) {
      final reloaded = await _mealStore.getMealsForDate(_selectedDate);
      _meals = List<MealEntry>.unmodifiable(reloaded);
    }
    _weeklyCalories = await _fetchWeeklyCalories();
    notifyListeners();
  }

  Future<void> saveSettings({
    String? apiKey,
    String? modelName,
    int? dailyCalorieGoal,
  }) async {
    if (apiKey != null) {
      await _settingsStore.saveApiKey(apiKey);
    }
    if (modelName != null) {
      await _settingsStore.saveModelName(modelName);
    }
    if (dailyCalorieGoal != null) {
      await _settingsStore.saveDailyCalorieGoal(dailyCalorieGoal);
    }
    _settings = await _settingsStore.load();
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await _settingsStore.clearApiKey();
    _settings = await _settingsStore.load();
    notifyListeners();
  }
}
