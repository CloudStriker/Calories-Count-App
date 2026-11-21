import 'dart:typed_data';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/screens/home_screen.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:calsnap/state/meal_log_controller.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  Future<MealLogController> buildSeededController() async {
    final mealStore = InMemoryMealStore();
    await mealStore.insertMeal(
      MealEntry.fromItems(
        id: 'seed-1',
        eatenAt: DateTime(2026, 11, 21, 8, 15),
        category: MealCategory.breakfast,
        title: 'Nasi Uduk',
        items: const <FoodItem>[
          FoodItem(
            name: 'Nasi uduk',
            portionLabel: '1 porsi',
            grams: 200,
            calories: 360,
            proteinGrams: 9,
            carbsGrams: 52,
            fatGrams: 12,
          ),
        ],
        syncStatus: HealthSyncStatus.synced,
      ),
    );

    final controller = MealLogController(
      settingsStore: FakeSettingsStore(
        const AppSettings(apiKey: 'test-key', dailyCalorieGoal: 2000),
      ),
      mealStore: mealStore,
      photoStore: FakePhotoStore(),
      foodAnalyzer: FakeFoodAnalyzer(),
      healthSync: FakeHealthSyncGateway(),
      initialDate: DateTime(2026, 11, 21),
    );
    await controller.initialize();
    return controller;
  }

  testWidgets('renders compact layout on Galaxy Z Fold 6 cover width', (
    tester,
  ) async {
    final controller = await buildSeededController();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-compact-layout')), findsOneWidget);
    expect(find.text('360 kkal'), findsNWidgets(2));
    expect(find.text('Nasi Uduk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders expanded 2-pane layout in dark mode on unfolded width', (
    tester,
  ) async {
    final controller = await buildSeededController();
    tester.view.physicalSize = const Size(840, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-expanded-layout')), findsOneWidget);
    expect(find.text('Nasi Uduk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera pick -> analyze -> save flow stores and syncs meal', (
    tester,
  ) async {
    // Valid 1x1 transparent PNG so Image.memory decodes without codec errors.
    final validPngBytes = Uint8List.fromList(const <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    final controller = await buildSeededController();
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HomeScreen(
          controller: controller,
          photoPicker: (_) async => PickedPhotoData(
            bytes: validPngBytes,
            mimeType: 'image/png',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kamera'));
    await tester.pumpAndSettle();

    expect(find.text('Analisis Kalori'), findsOneWidget);
    await tester.tap(find.text('Analisis Kalori'));
    await tester.pumpAndSettle();

    expect(find.text('Simpan & Sinkron'), findsOneWidget);
    expect(find.text('455 kkal'), findsOneWidget);

    await tester.tap(find.text('Simpan & Sinkron'));
    await tester.pumpAndSettle();

    expect(controller.meals, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
