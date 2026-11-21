import 'dart:typed_data';

import 'package:calsnap/models/meal_entry.dart';

class FoodAnalysisResult {
  FoodAnalysisResult({
    required this.mealTitle,
    required List<FoodItem> items,
    this.notes,
  }) : items = List<FoodItem>.unmodifiable(items);

  final String mealTitle;
  final List<FoodItem> items;
  final String? notes;
}

class FoodAnalysisException implements Exception {
  const FoodAnalysisException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Swappable abstraction for cloud or on-device vision food calorie analyzers.
abstract class FoodAnalyzer {
  Future<FoodAnalysisResult> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String? userNote,
  });
}
