import 'dart:io';
import 'dart:typed_data';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/screens/home_screen.dart';
import 'package:calsnap/services/health_sync_service.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:calsnap/state/meal_log_controller.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

final Uint8List _validPngBytes = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

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

    expect(
      find.byKey(const ValueKey<String>('home-compact-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-week-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-meal-slots')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('weekly-trend-card')),
      findsOneWidget,
    );
    expect(find.text('360 kkal'), findsNWidgets(3));
    expect(find.text('Nasi Uduk'), findsOneWidget);

    for (final ringKey in const <String>[
      'calorie-progress-ring',
      'macro-ring-protein',
      'macro-ring-carbs',
      'macro-ring-fat',
    ]) {
      final finder = find.byKey(ValueKey<String>(ringKey));
      expect(finder, findsOneWidget);
      final size = tester.getSize(finder);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tapping meal card opens detail bottom sheet and allows deleting meal', (
    tester,
  ) async {
    final controller = await buildSeededController();
    tester.view.physicalSize = const Size(360, 800);
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

    await tester.tap(find.text('Nasi Uduk'));
    await tester.pumpAndSettle();

    expect(find.text('Komponen Makanan'), findsOneWidget);
    expect(find.text('Hapus Catatan'), findsOneWidget);

    await tester.tap(find.text('Hapus Catatan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(controller.meals, isEmpty);
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

    expect(
      find.byKey(const ValueKey<String>('home-expanded-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('weekly-trend-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-meal-slots')),
      findsOneWidget,
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor ?? Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor, const Color(0xFF0A0A0A));
    expect(find.text('Nasi Uduk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera pick -> analyze -> save flow stores and syncs meal', (
    tester,
  ) async {
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
            bytes: _validPngBytes,
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

  testWidgets('renders cleanly with reduced motion enabled', (tester) async {
    final controller = await buildSeededController();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: HomeScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('18%'), findsOneWidget);
    expect(find.text('Nasi Uduk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'renders photo banner meal card, detail sheet photo, and swipes week strip',
      (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('calsnap_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final photoFile = File('${tempDir.path}/meal.png')
      ..writeAsBytesSync(_validPngBytes);

    final mealStore = InMemoryMealStore();
    await mealStore.insertMeal(
      MealEntry.fromItems(
        id: 'photo-1',
        eatenAt: DateTime(2026, 11, 21, 12, 30),
        category: MealCategory.lunch,
        title: 'Nasi Gudeg',
        photoPath: photoFile.path,
        items: const <FoodItem>[
          FoodItem(
            name: 'Nasi gudeg',
            portionLabel: '1 porsi',
            grams: 280,
            calories: 520,
            proteinGrams: 18,
            carbsGrams: 64,
            fatGrams: 19,
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

    tester.view.physicalSize = const Size(360, 800);
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

    expect(find.bySemanticsLabel('Foto Nasi Gudeg'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nasi Gudeg'));
    await tester.pumpAndSettle();
    expect(find.text('Komponen Makanan'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto Nasi Gudeg'), findsNWidgets(2));

    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const ValueKey<String>('home-week-strip')),
      const Offset(300, 0),
      800,
    );
    await tester.pumpAndSettle();

    expect(controller.selectedDate, DateTime(2026, 11, 14));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping trend bar selects date, shows +N lainnya chip, and opens HC settings', (
    tester,
  ) async {
    final mealStore = InMemoryMealStore();
    await mealStore.insertMeal(
      MealEntry.fromItems(
        id: 'many-items',
        eatenAt: DateTime(2026, 11, 21, 12, 30),
        category: MealCategory.lunch,
        title: 'Nasi Padang',
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
          FoodItem(
            name: 'Rendang',
            portionLabel: '1 potong',
            grams: 90,
            calories: 250,
            proteinGrams: 22,
            carbsGrams: 4,
            fatGrams: 16,
          ),
          FoodItem(
            name: 'Daun singkong',
            portionLabel: '1 porsi',
            grams: 60,
            calories: 40,
            proteinGrams: 2,
            carbsGrams: 5,
            fatGrams: 1,
          ),
          FoodItem(
            name: 'Sambal ijo',
            portionLabel: '1 sdm',
            grams: 20,
            calories: 35,
            proteinGrams: 0.5,
            carbsGrams: 2,
            fatGrams: 3,
          ),
        ],
        syncStatus: HealthSyncStatus.synced,
      ),
    );
    final healthSync = FakeHealthSyncGateway()
      ..todaySummary = const HealthConnectDaySummary(
        recordCount: 2,
        totalCalories: 850,
      );
    final controller = MealLogController(
      settingsStore: FakeSettingsStore(
        const AppSettings(apiKey: 'test-key', dailyCalorieGoal: 2000),
      ),
      mealStore: mealStore,
      photoStore: FakePhotoStore(),
      foodAnalyzer: FakeFoodAnalyzer(),
      healthSync: healthSync,
      initialDate: DateTime(2026, 11, 21),
    );
    await controller.initialize();

    tester.view.physicalSize = const Size(360, 800);
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

    expect(find.text('+1 lainnya'), findsOneWidget);

    final trendCard = find.byKey(const ValueKey<String>('weekly-trend-card'));
    final jumBar = find.descendant(of: trendCard, matching: find.text('Jum'));
    await tester.scrollUntilVisible(
      jumBar,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(jumBar);
    await tester.pumpAndSettle();
    expect(controller.selectedDate, DateTime(2026, 11, 20));

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    final diagnosticFinder = find.text(
      'Tercatat di Health Connect hari ini: 2 catatan (850 kkal)',
    );
    await tester.scrollUntilVisible(
      diagnosticFinder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(diagnosticFinder, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Buka Health Connect'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Health Connect'));
    await tester.pumpAndSettle();
    expect(healthSync.openedSettingsCount, 1);
    expect(tester.takeException(), isNull);
  });
}
