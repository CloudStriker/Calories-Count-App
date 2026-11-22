import 'dart:typed_data';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/state/meal_log_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('saveMeal stores locally and syncs to Health Connect', () async {
    final mealStore = InMemoryMealStore();
    final photoStore = FakePhotoStore();
    final healthSync = FakeHealthSyncGateway();
    final controller = MealLogController(
      settingsStore: FakeSettingsStore(),
      mealStore: mealStore,
      photoStore: photoStore,
      foodAnalyzer: FakeFoodAnalyzer(),
      healthSync: healthSync,
      initialDate: DateTime(2026, 11, 21),
    );

    await controller.initialize();

    final saved = await controller.saveMeal(
      eatenAt: DateTime(2026, 11, 21, 12, 30),
      category: MealCategory.lunch,
      title: 'Nasi Ayam Bakar',
      items: const <FoodItem>[
        FoodItem(
          name: 'Nasi putih',
          portionLabel: '1 porsi',
          grams: 150,
          calories: 200,
          proteinGrams: 4,
          carbsGrams: 44,
          fatGrams: 0.4,
        ),
      ],
      photoBytes: Uint8List.fromList(<int>[9, 8, 7]),
    );

    expect(saved.syncStatus, HealthSyncStatus.synced);
    expect(controller.meals, hasLength(1));
    expect(controller.weeklyCalories[DateTime(2026, 11, 21)], 200);
    expect(healthSync.writtenMeals, hasLength(1));
    expect(photoStore.saved, hasLength(1));
  });

  test('keeps local record when sync fails and retries cleanly', () async {
    final mealStore = InMemoryMealStore();
    final photoStore = FakePhotoStore();
    final healthSync = FakeHealthSyncGateway()..shouldFailWrite = true;
    final controller = MealLogController(
      settingsStore: FakeSettingsStore(),
      mealStore: mealStore,
      photoStore: photoStore,
      foodAnalyzer: FakeFoodAnalyzer(),
      healthSync: healthSync,
      initialDate: DateTime(2026, 11, 21),
    );

    await controller.initialize();
    final saved = await controller.saveMeal(
      eatenAt: DateTime(2026, 11, 21, 19, 0),
      category: MealCategory.dinner,
      title: 'Bakso',
      items: const <FoodItem>[
        FoodItem(
          name: 'Bakso sapi',
          portionLabel: '1 mangkuk',
          grams: 300,
          calories: 380,
          proteinGrams: 20,
          carbsGrams: 38,
          fatGrams: 15,
        ),
      ],
      photoBytes: Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(saved.syncStatus, HealthSyncStatus.failed);
    expect(controller.meals.single.syncStatus, HealthSyncStatus.failed);

    healthSync.shouldFailWrite = false;
    final retried = await controller.retryHealthSync(controller.meals.single);
    expect(retried.syncStatus, HealthSyncStatus.synced);
    expect(controller.meals.single.syncStatus, HealthSyncStatus.synced);

    await controller.deleteMeal(controller.meals.single);
    expect(controller.meals, isEmpty);
    expect(controller.weeklyCalories[DateTime(2026, 11, 21)], isNull);
    expect(photoStore.deletedPaths, hasLength(1));
  });
}
