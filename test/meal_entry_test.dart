import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guesses meal category from hour of day', () {
    expect(
      MealCategory.guessFromTime(DateTime(2026, 11, 21, 7, 30)),
      MealCategory.breakfast,
    );
    expect(
      MealCategory.guessFromTime(DateTime(2026, 11, 21, 12, 15)),
      MealCategory.lunch,
    );
    expect(
      MealCategory.guessFromTime(DateTime(2026, 11, 21, 19, 0)),
      MealCategory.dinner,
    );
    expect(
      MealCategory.guessFromTime(DateTime(2026, 11, 21, 23, 0)),
      MealCategory.snack,
    );
  });

  test('computes totals and survives SQLite map round-trip', () {
    final eatenAt = DateTime(2026, 11, 21, 13, 15);
    final meal = MealEntry.fromItems(
      id: 'meal-1',
      eatenAt: eatenAt,
      category: MealCategory.lunch,
      title: 'Gado-gado',
      photoPath: '/tmp/gado.jpg',
      userNote: 'bumbu dipisah',
      items: const <FoodItem>[
        FoodItem(
          name: 'Sayuran rebus & tahu',
          portionLabel: '1 piring',
          grams: 220,
          calories: 210,
          proteinGrams: 12,
          carbsGrams: 20,
          fatGrams: 8,
        ),
        FoodItem(
          name: 'Bumbu kacang',
          portionLabel: '2 sdm',
          grams: 45,
          calories: 180,
          proteinGrams: 6,
          carbsGrams: 9,
          fatGrams: 14,
        ),
      ],
      syncStatus: HealthSyncStatus.synced,
      healthRecordId: 'meal-1',
    );

    expect(meal.totalCalories, 390);
    expect(meal.totalProtein, 18);
    expect(meal.totalCarbs, 29);
    expect(meal.totalFat, 22);

    final restored = MealEntry.fromDbMap(meal.toDbMap());
    expect(restored.id, meal.id);
    expect(restored.eatenAt, eatenAt);
    expect(restored.category, MealCategory.lunch);
    expect(restored.title, 'Gado-gado');
    expect(restored.items, hasLength(2));
    expect(restored.totalCalories, 390);
    expect(restored.syncStatus, HealthSyncStatus.synced);

    final totals = DailyTotals.fromMeals(<MealEntry>[restored]);
    expect(totals.calories, 390);
    expect(totals.mealCount, 1);
  });

  test('formats relative dates and HH:mm cleanly', () {
    final now = DateTime(2026, 11, 21, 18, 0);
    expect(formatRelativeDay(DateTime(2026, 11, 21, 9, 5), now: now), 'Hari Ini');
    expect(formatRelativeDay(DateTime(2026, 11, 20, 22, 0), now: now), 'Kemarin');
    expect(formatRelativeDay(DateTime(2026, 11, 18, 8, 0), now: now), 'Rab, 18 Nov');
    expect(formatTimeHm(DateTime(2026, 11, 21, 7, 5)), '07:05');
  });
}
