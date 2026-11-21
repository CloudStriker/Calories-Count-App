import 'package:calsnap/screens/home_screen.dart';
import 'package:calsnap/services/gemini_food_analyzer.dart';
import 'package:calsnap/services/health_sync_service.dart';
import 'package:calsnap/services/meal_database.dart';
import 'package:calsnap/services/photo_storage.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:calsnap/state/meal_log_controller.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsStore = DeviceSettingsStore();
  final controller = MealLogController(
    settingsStore: settingsStore,
    mealStore: SqliteMealStore(),
    photoStore: LocalPhotoStore(),
    foodAnalyzer: GeminiFoodAnalyzer(settingsStore: settingsStore),
    healthSync: HealthConnectSyncService(),
  )..initialize();

  runApp(CalSnapApp(controller: controller));
}

class CalSnapApp extends StatelessWidget {
  const CalSnapApp({
    super.key,
    required this.controller,
  });

  final MealLogController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller),
    );
  }
}
