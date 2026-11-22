import 'dart:typed_data';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/services/food_analyzer.dart';
import 'package:calsnap/services/health_sync_service.dart';
import 'package:calsnap/services/meal_database.dart';
import 'package:calsnap/services/photo_storage.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:calsnap/utils/date_format.dart';

class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore([AppSettings? initial])
      : _settings = initial ?? const AppSettings();

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    _settings = trimmed.isEmpty
        ? _settings.copyWith(clearApiKey: true)
        : _settings.copyWith(apiKey: trimmed);
  }

  @override
  Future<void> clearApiKey() async {
    _settings = _settings.copyWith(clearApiKey: true);
  }

  @override
  Future<void> saveModelName(String modelName) async {
    _settings = _settings.copyWith(modelName: modelName.trim());
  }

  @override
  Future<void> saveDailyCalorieGoal(int goal) async {
    _settings = _settings.copyWith(dailyCalorieGoal: goal);
  }
}

class InMemoryMealStore implements MealStore {
  final List<MealEntry> rows = <MealEntry>[];

  @override
  Future<List<MealEntry>> getMealsForDate(DateTime date) async {
    final matches = rows
        .where((meal) => isSameDay(meal.eatenAt, date))
        .toList()
      ..sort((a, b) => b.eatenAt.compareTo(a.eatenAt));
    return matches;
  }

  @override
  Future<Map<DateTime, double>> getDailyCaloriesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final rangeStart = startOfDay(startDate);
    final normalizedEnd = startOfDay(endDate);
    final totals = <DateTime, double>{};
    for (final meal in rows) {
      final day = startOfDay(meal.eatenAt);
      if (day.isBefore(rangeStart) || day.isAfter(normalizedEnd)) {
        continue;
      }
      totals[day] = (totals[day] ?? 0) + meal.totalCalories;
    }
    return totals;
  }

  @override
  Future<void> insertMeal(MealEntry meal) async {
    rows.removeWhere((existing) => existing.id == meal.id);
    rows.add(meal);
  }

  @override
  Future<void> updateSyncStatus({
    required String mealId,
    required HealthSyncStatus status,
    String? error,
    String? recordId,
  }) async {
    final index = rows.indexWhere((meal) => meal.id == mealId);
    if (index == -1) {
      return;
    }
    rows[index] = rows[index].copyWith(
      syncStatus: status,
      syncError: error,
      clearSyncError: error == null,
      healthRecordId: recordId,
    );
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    rows.removeWhere((meal) => meal.id == mealId);
  }
}

class FakePhotoStore implements PhotoStore {
  final Map<String, Uint8List> saved = <String, Uint8List>{};
  final List<String> deletedPaths = <String>[];

  @override
  Future<String> saveMealPhoto(Uint8List bytes, String mealId) async {
    final path = '/tmp/calsnap_test/$mealId.jpg';
    saved[path] = bytes;
    return path;
  }

  @override
  Future<void> deleteMealPhoto(String? path) async {
    if (path != null) {
      deletedPaths.add(path);
      saved.remove(path);
    }
  }
}

class FakeFoodAnalyzer implements FoodAnalyzer {
  FoodAnalysisResult? nextResult;
  FoodAnalysisException? nextException;

  @override
  Future<FoodAnalysisResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? userNote,
  }) async {
    if (nextException != null) {
      throw nextException!;
    }
    return nextResult ??
        FoodAnalysisResult(
          mealTitle: 'Nasi Ayam Bakar',
          items: const <FoodItem>[
            FoodItem(
              name: 'Nasi putih',
              portionLabel: '1 porsi',
              grams: 150,
              calories: 195,
              proteinGrams: 4,
              carbsGrams: 42,
              fatGrams: 0.4,
            ),
            FoodItem(
              name: 'Ayam bakar',
              portionLabel: '1 potong',
              grams: 120,
              calories: 260,
              proteinGrams: 28,
              carbsGrams: 6,
              fatGrams: 13,
            ),
          ],
          notes: 'Estimasi standar.',
        );
  }
}

class FakeHealthSyncGateway implements HealthSyncGateway {
  HealthAvailability availability = HealthAvailability.available;
  bool permitted = true;
  bool shouldFailWrite = false;
  HealthConnectDaySummary? todaySummary;
  int openedSettingsCount = 0;
  final List<MealEntry> writtenMeals = <MealEntry>[];

  @override
  Future<HealthAvailability> checkAvailability() async => availability;

  @override
  Future<bool> hasWritePermission() async => permitted;

  @override
  Future<bool> requestWritePermission() async {
    permitted = true;
    return true;
  }

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<HealthConnectDaySummary?> readTodaySyncedSummary(DateTime date) async =>
      todaySummary;

  @override
  Future<bool> openHealthConnectSettings() async {
    openedSettingsCount += 1;
    return true;
  }

  @override
  Future<HealthSyncResult> writeMeal(MealEntry meal) async {
    if (shouldFailWrite) {
      return const HealthSyncResult(
        status: HealthSyncStatus.failed,
        errorMessage: 'Koneksi Health Connect gagal.',
      );
    }
    writtenMeals.add(meal);
    return HealthSyncResult(
      status: HealthSyncStatus.synced,
      recordId: meal.id,
    );
  }
}
