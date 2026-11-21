import 'dart:math' as math;

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

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
    final rawRatio = totals.calories / goal;
    final progress = rawRatio.clamp(0.0, 1.0);
    final pct = (rawRatio * 100).round().clamp(0, 999);
    final isOver = consumed > goal;

    final macroCalTotal = (totals.proteinGrams * 4) +
        (totals.carbsGrams * 4) +
        (totals.fatGrams * 9);
    final proteinShare =
        macroCalTotal > 0 ? (totals.proteinGrams * 4) / macroCalTotal : 0.0;
    final carbsShare =
        macroCalTotal > 0 ? (totals.carbsGrams * 4) / macroCalTotal : 0.0;
    final fatShare =
        macroCalTotal > 0 ? (totals.fatGrams * 9) / macroCalTotal : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'RINGKASAN HARI INI',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$consumed kkal',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: scheme.onSurface,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target $goal kkal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                          fontWeight: FontWeight.w500,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isOver ? colors.warningBg : colors.mutedSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOver
                              ? 'Lebih ${delta.abs()} kkal · ${totals.mealCount} catatan'
                              : 'Sisa $delta kkal · ${totals.mealCount} catatan',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isOver ? colors.warningFg : colors.mutedText,
                            fontWeight: FontWeight.w700,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _CalorieRing(
                  progress: progress,
                  percentLabel: '$pct%',
                  ringColor: isOver ? scheme.secondary : scheme.primary,
                  trackColor: colors.mutedSurface,
                  disableAnimations: disableAnimations,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MacroChip(
                    label: 'Protein',
                    grams: totals.proteinGrams,
                    share: proteinShare,
                    accentColor: colors.proteinColor,
                    disableAnimations: disableAnimations,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Karbo',
                    grams: totals.carbsGrams,
                    share: carbsShare,
                    accentColor: colors.carbsColor,
                    disableAnimations: disableAnimations,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroChip(
                    label: 'Lemak',
                    grams: totals.fatGrams,
                    share: fatShare,
                    accentColor: colors.fatColor,
                    disableAnimations: disableAnimations,
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

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.progress,
    required this.percentLabel,
    required this.ringColor,
    required this.trackColor,
    required this.disableAnimations,
  });

  final double progress;
  final String percentLabel;
  final Color ringColor;
  final Color trackColor;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 360),
        curve: CalSnapMotion.easeOut,
        builder: (context, animatedProgress, _) {
          return CustomPaint(
            painter: _CalorieRingPainter(
              progress: animatedProgress,
              ringColor: ringColor,
              trackColor: trackColor,
            ),
            child: Center(
              child: Text(
                percentLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: tabularFigures,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  const _CalorieRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) {
      return;
    }

    final arcPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_CalorieRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.trackColor != trackColor;
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.grams,
    required this.share,
    required this.accentColor,
    required this.disableAnimations,
  });

  final String label;
  final double grams;
  final double share;
  final Color accentColor;
  final bool disableAnimations;

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
              fontWeight: FontWeight.w800,
              fontFeatures: tabularFigures,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: colors.border),
                  AnimatedFractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    duration: disableAnimations
                        ? Duration.zero
                        : CalSnapMotion.transitionDuration,
                    curve: CalSnapMotion.easeOut,
                    widthFactor: share.clamp(0.0, 1.0),
                    heightFactor: 1.0,
                    child: ColoredBox(color: accentColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
