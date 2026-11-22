import 'dart:math' as math;

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:material_ui/material_ui.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    super.key,
    required this.totals,
    required this.dailyGoal,
    this.eyebrowLabel = 'KALORI HARI INI',
  });

  final DailyTotals totals;
  final int dailyGoal;
  final String eyebrowLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.calColors;
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final goal = dailyGoal <= 0 ? 2000 : dailyGoal;
    final consumed = totals.calories.round();
    final delta = goal - consumed;
    final rawRatio = totals.calories / goal;
    final progress = rawRatio.clamp(0.0, 1.0);
    final pct = (rawRatio * 100).round().clamp(0, 999);
    final isOver = consumed > goal;

    final proteinCal = totals.proteinGrams * 4;
    final carbsCal = totals.carbsGrams * 4;
    final fatCal = totals.fatGrams * 9;
    final macroCalTotal = proteinCal + carbsCal + fatCal;
    final proteinShare = macroCalTotal > 0 ? proteinCal / macroCalTotal : 0.0;
    final carbsShare = macroCalTotal > 0 ? carbsCal / macroCalTotal : 0.0;
    final fatShare = macroCalTotal > 0 ? fatCal / macroCalTotal : 0.0;

    final proteinPct = (proteinShare * 100).round();
    final carbsPct = (carbsShare * 100).round();
    final fatPct =
        macroCalTotal > 0 ? (100 - proteinPct - carbsPct).clamp(0, 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: isDark
                ? BorderSide(color: Colors.white.withValues(alpha: 0.06))
                : BorderSide.none,
          ),
          child: DecoratedBox(
            decoration: isDark
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF1A1B1F), Color(0xFF151515)],
                    ),
                  )
                : const BoxDecoration(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              eyebrowLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.mutedText,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.9,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text.rich(
                              TextSpan(
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: formatThousandsId(consumed),
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      height: 1.05,
                                      color: scheme.onSurface,
                                      fontFeatures: tabularFigures,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' kkal',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.78,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isOver
                                  ? 'Lebih ${formatThousandsId(delta.abs())} dari ${formatThousandsId(goal)} kkal'
                                  : 'Sisa ${formatThousandsId(delta)} dari ${formatThousandsId(goal)} kkal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    isOver ? colors.warningFg : colors.mutedText,
                                fontWeight:
                                    isOver ? FontWeight.w600 : FontWeight.w500,
                                fontFeatures: tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _ProgressRing(
                        key: const ValueKey<String>('calorie-progress-ring'),
                        size: 84,
                        strokeWidth: 7.5,
                        progress: progress,
                        ringColor: isOver ? colors.warningFg : scheme.primary,
                        trackColor: colors.mutedSurface,
                        disableAnimations: disableAnimations,
                        center: Text(
                          '$pct%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 6,
                      child: macroCalTotal <= 0
                          ? ColoredBox(color: colors.mutedSurface)
                          : Row(
                              children: <Widget>[
                                if (proteinCal > 0)
                                  Expanded(
                                    flex: math.max(1, proteinCal.round()),
                                    child: ColoredBox(color: colors.proteinColor),
                                  ),
                                if (carbsCal > 0)
                                  Expanded(
                                    flex: math.max(1, carbsCal.round()),
                                    child: ColoredBox(color: colors.carbsColor),
                                  ),
                                if (fatCal > 0)
                                  Expanded(
                                    flex: math.max(1, fatCal.round()),
                                    child: ColoredBox(color: colors.fatColor),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    macroCalTotal <= 0
                        ? 'Belum ada data makro hari ini'
                        : 'Proporsi kalori: P $proteinPct% · K $carbsPct% · L $fatPct%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.mutedText,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _MacroRingCard(
                key: const ValueKey<String>('macro-ring-protein'),
                badge: 'P',
                label: 'Protein',
                grams: totals.proteinGrams,
                share: proteinShare,
                accentColor: colors.proteinColor,
                disableAnimations: disableAnimations,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroRingCard(
                key: const ValueKey<String>('macro-ring-carbs'),
                badge: 'K',
                label: 'Karbo',
                grams: totals.carbsGrams,
                share: carbsShare,
                accentColor: colors.carbsColor,
                disableAnimations: disableAnimations,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroRingCard(
                key: const ValueKey<String>('macro-ring-fat'),
                badge: 'L',
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
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.disableAnimations,
    required this.center,
  });

  final double size;
  final double strokeWidth;
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final bool disableAnimations;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 360),
        curve: CalSnapMotion.easeOut,
        builder: (context, animatedProgress, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: animatedProgress,
              strokeWidth: strokeWidth,
              ringColor: ringColor,
              trackColor: trackColor,
            ),
            child: child,
          );
        },
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.trackColor != trackColor;
}

class _MacroRingCard extends StatelessWidget {
  const _MacroRingCard({
    super.key,
    required this.badge,
    required this.label,
    required this.grams,
    required this.share,
    required this.accentColor,
    required this.disableAnimations,
  });

  final String badge;
  final String label;
  final double grams;
  final double share;
  final Color accentColor;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.calColors;
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? BorderSide(color: Colors.white.withValues(alpha: 0.06))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _ProgressRing(
                  size: 30,
                  strokeWidth: 3.5,
                  progress: share,
                  ringColor: accentColor,
                  trackColor: colors.mutedSurface,
                  disableAnimations: disableAnimations,
                  center: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${grams.round()} g',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MacroPill extends StatelessWidget {
  const MacroPill({
    super.key,
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accentColor,
          fontFeatures: tabularFigures,
        ),
      ),
    );
  }
}
