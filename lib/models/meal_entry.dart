import 'dart:convert';

enum MealCategory {
  breakfast('Sarapan', 'breakfast'),
  lunch('Makan Siang', 'lunch'),
  dinner('Makan Malam', 'dinner'),
  snack('Camilan', 'snack');

  const MealCategory(this.labelId, this.storageKey);

  final String labelId;
  final String storageKey;

  static MealCategory fromStorageKey(String? value) {
    for (final category in MealCategory.values) {
      if (category.storageKey == value) {
        return category;
      }
    }
    return MealCategory.snack;
  }

  static MealCategory guessFromTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 4 && hour <= 10) {
      return MealCategory.breakfast;
    }
    if (hour >= 11 && hour <= 15) {
      return MealCategory.lunch;
    }
    if (hour >= 16 && hour <= 21) {
      return MealCategory.dinner;
    }
    return MealCategory.snack;
  }
}

enum HealthSyncStatus {
  pending('pending'),
  synced('synced'),
  failed('failed'),
  skipped('skipped');

  const HealthSyncStatus(this.storageKey);

  final String storageKey;

  static HealthSyncStatus fromStorageKey(String? value) {
    for (final status in HealthSyncStatus.values) {
      if (status.storageKey == value) {
        return status;
      }
    }
    return HealthSyncStatus.pending;
  }
}

double _clampNonNegative(Object? raw) {
  if (raw is num) {
    final value = raw.toDouble();
    if (value.isNaN || value.isInfinite || value < 0) {
      return 0;
    }
    return value;
  }
  if (raw is String) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return 0;
    }
    return parsed;
  }
  return 0;
}

class FoodItem {
  const FoodItem({
    required this.name,
    required this.portionLabel,
    required this.grams,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final String name;
  final String portionLabel;
  final double grams;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  FoodItem copyWith({
    String? name,
    String? portionLabel,
    double? grams,
    double? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
  }) {
    return FoodItem(
      name: name ?? this.name,
      portionLabel: portionLabel ?? this.portionLabel,
      grams: grams ?? this.grams,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'portion_label': portionLabel,
        'grams': grams,
        'calories': calories,
        'protein_g': proteinGrams,
        'carbs_g': carbsGrams,
        'fat_g': fatGrams,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] ?? '').toString().trim();
    final rawPortion = (json['portion_label'] ?? '').toString().trim();
    return FoodItem(
      name: rawName.isEmpty ? 'Makanan' : rawName,
      portionLabel: rawPortion.isEmpty ? '1 porsi' : rawPortion,
      grams: _clampNonNegative(json['grams']),
      calories: _clampNonNegative(json['calories']),
      proteinGrams: _clampNonNegative(json['protein_g']),
      carbsGrams: _clampNonNegative(json['carbs_g']),
      fatGrams: _clampNonNegative(json['fat_g']),
    );
  }
}

class MealEntry {
  MealEntry({
    required this.id,
    required this.eatenAt,
    required this.category,
    required this.title,
    this.photoPath,
    this.userNote,
    required List<FoodItem> items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.syncStatus,
    this.syncError,
    this.healthRecordId,
  }) : items = List<FoodItem>.unmodifiable(items);

  factory MealEntry.fromItems({
    required String id,
    required DateTime eatenAt,
    required MealCategory category,
    required String title,
    String? photoPath,
    String? userNote,
    required List<FoodItem> items,
    HealthSyncStatus syncStatus = HealthSyncStatus.pending,
    String? syncError,
    String? healthRecordId,
  }) {
    final summary = DailyTotals.fromItems(items);
    return MealEntry(
      id: id,
      eatenAt: eatenAt,
      category: category,
      title: title.trim().isEmpty ? 'Makanan' : title.trim(),
      photoPath: photoPath,
      userNote: userNote,
      items: items,
      totalCalories: summary.calories,
      totalProtein: summary.proteinGrams,
      totalCarbs: summary.carbsGrams,
      totalFat: summary.fatGrams,
      syncStatus: syncStatus,
      syncError: syncError,
      healthRecordId: healthRecordId,
    );
  }

  final String id;
  final DateTime eatenAt;
  final MealCategory category;
  final String title;
  final String? photoPath;
  final String? userNote;
  final List<FoodItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final HealthSyncStatus syncStatus;
  final String? syncError;
  final String? healthRecordId;

  MealEntry copyWith({
    String? id,
    DateTime? eatenAt,
    MealCategory? category,
    String? title,
    String? photoPath,
    String? userNote,
    List<FoodItem>? items,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    HealthSyncStatus? syncStatus,
    String? syncError,
    bool clearSyncError = false,
    String? healthRecordId,
  }) {
    return MealEntry(
      id: id ?? this.id,
      eatenAt: eatenAt ?? this.eatenAt,
      category: category ?? this.category,
      title: title ?? this.title,
      photoPath: photoPath ?? this.photoPath,
      userNote: userNote ?? this.userNote,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      healthRecordId: healthRecordId ?? this.healthRecordId,
    );
  }

  Map<String, Object?> toDbMap() => <String, Object?>{
        'id': id,
        'eaten_at': eatenAt.millisecondsSinceEpoch,
        'category': category.storageKey,
        'title': title,
        'photo_path': photoPath,
        'user_note': userNote,
        'items_json': jsonEncode(items.map((item) => item.toJson()).toList()),
        'total_calories': totalCalories,
        'total_protein': totalProtein,
        'total_carbs': totalCarbs,
        'total_fat': totalFat,
        'sync_status': syncStatus.storageKey,
        'sync_error': syncError,
        'health_record_id': healthRecordId,
      };

  factory MealEntry.fromDbMap(Map<String, Object?> map) {
    final rawItems = map['items_json'] as String? ?? '[]';
    final decoded = jsonDecode(rawItems);
    final items = <FoodItem>[];
    if (decoded is List) {
      for (final raw in decoded) {
        if (raw is Map<String, dynamic>) {
          items.add(FoodItem.fromJson(raw));
        } else if (raw is Map) {
          items.add(FoodItem.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return MealEntry(
      id: map['id'] as String,
      eatenAt: DateTime.fromMillisecondsSinceEpoch(map['eaten_at'] as int),
      category: MealCategory.fromStorageKey(map['category'] as String?),
      title: map['title'] as String? ?? 'Makanan',
      photoPath: map['photo_path'] as String?,
      userNote: map['user_note'] as String?,
      items: items,
      totalCalories: _clampNonNegative(map['total_calories']),
      totalProtein: _clampNonNegative(map['total_protein']),
      totalCarbs: _clampNonNegative(map['total_carbs']),
      totalFat: _clampNonNegative(map['total_fat']),
      syncStatus: HealthSyncStatus.fromStorageKey(map['sync_status'] as String?),
      syncError: map['sync_error'] as String?,
      healthRecordId: map['health_record_id'] as String?,
    );
  }
}

class DailyTotals {
  const DailyTotals({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.mealCount,
  });

  factory DailyTotals.fromItems(List<FoodItem> items) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final item in items) {
      calories += item.calories;
      protein += item.proteinGrams;
      carbs += item.carbsGrams;
      fat += item.fatGrams;
    }
    return DailyTotals(
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      mealCount: items.isEmpty ? 0 : 1,
    );
  }

  factory DailyTotals.fromMeals(List<MealEntry> meals) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final meal in meals) {
      calories += meal.totalCalories;
      protein += meal.totalProtein;
      carbs += meal.totalCarbs;
      fat += meal.totalFat;
    }
    return DailyTotals(
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      mealCount: meals.length,
    );
  }

  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final int mealCount;
}
