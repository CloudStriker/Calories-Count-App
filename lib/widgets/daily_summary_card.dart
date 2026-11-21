import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    super.key,
    required this.totals,
    required this.dailyGoal,
  });

  final DailyTotals totals;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.calColors;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final goal = dailyGoal <= 0 ? 2000 : dailyGoal;
    final consumed = totals.calories.round();
    final delta = goal - consumed;
    final progress = (totals.calories / goal).clamp(0.0, 1.0);
    final isOver = consumed > goal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$consumed kkal',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  'Target $goal kkal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(color: colors.mutedSurface),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        widthFactor: progress,
                        child: ColoredBox(
                          color: isOver ? scheme.secondary : scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOver
                  ? 'Melebihi target ${delta.abs()} kkal (${totals.mealCount} catatan)'
                  : 'Sisa $delta kkal hari ini (${totals.mealCount} catatan)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOver ? colors.warningFg : colors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MacroChip(
                    label: 'Protein',
                    grams: totals.proteinGrams,
                    accentColor: colors.proteinColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Karbo',
                    grams: totals.carbsGrams,
                    accentColor: colors.carbsColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Lemak',
                    grams: totals.fatGrams,
                    accentColor: colors.fatColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.grams,
    required this.accentColor,
  });

  final String label;
  final double grams;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.calColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.mutedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${grams.round()} g',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
