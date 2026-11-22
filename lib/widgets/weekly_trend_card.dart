import 'dart:math' as math;

import 'package:calsnap/theme/app_theme.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class WeeklyTrendCard extends StatelessWidget {
  const WeeklyTrendCard({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.dailyCalories,
    required this.dailyGoal,
    required this.onSelectDate,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final Map<DateTime, double> dailyCalories;
  final int dailyGoal;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.calColors;
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final goal = dailyGoal <= 0 ? 2000 : dailyGoal;

    var maxDayCalories = 0.0;
    var activeDays = 0;
    var activeCaloriesSum = 0.0;
    for (final day in days) {
      final kcal = dailyCalories[startOfDay(day)] ?? 0;
      if (kcal > maxDayCalories) {
        maxDayCalories = kcal;
      }
      if (kcal > 0) {
        activeDays += 1;
        activeCaloriesSum += kcal;
      }
    }

    final maxScale = math.max(
      500.0,
      math.max(goal * 1.15, maxDayCalories * 1.1),
    );
    const barAreaHeight = 82.0;
    final labelBandHeight = math.max(
      24.0,
      6.0 + textScaler.scale(15.0).ceilToDouble(),
    );
    final goalLineBottom = (goal / maxScale).clamp(0.0, 1.0) * barAreaHeight;
    final avgLabel = activeDays > 0
        ? 'Rata-rata ${formatThousandsId((activeCaloriesSum / activeDays).round())} kkal/hr'
        : 'Target ${formatThousandsId(goal)} kkal';

    return Card(
      key: const ValueKey<String>('weekly-trend-card'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: isDark
            ? BorderSide(color: Colors.white.withValues(alpha: 0.06))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'TREN 7 HARI',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  Text(
                    avgLabel,
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
            const SizedBox(height: 14),
            SizedBox(
              height: barAreaHeight + labelBandHeight,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: labelBandHeight + goalLineBottom,
                    child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: _DashedLinePainter(color: colors.border),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: days.map((day) {
                      final normalized = startOfDay(day);
                      final kcal = dailyCalories[normalized] ?? 0;
                      final isSelected = isSameDay(normalized, selectedDate);
                      final isOver = kcal > goal;
                      final barHeight = kcal <= 0
                          ? 4.0
                          : ((kcal / maxScale).clamp(0.0, 1.0) * barAreaHeight)
                              .clamp(6.0, barAreaHeight);
                      final Color barColor;
                      if (kcal <= 0) {
                        barColor = isSelected
                            ? scheme.primary.withValues(alpha: 0.5)
                            : colors.border;
                      } else if (isSelected) {
                        barColor = isOver ? colors.warningFg : scheme.primary;
                      } else {
                        barColor = isOver
                            ? colors.warningFg.withValues(alpha: 0.72)
                            : colors.proteinColor.withValues(
                                alpha: isDark ? 0.58 : 0.65,
                              );
                      }

                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: isSelected,
                          label:
                              '${shortWeekdayLabel(normalized)} ${normalized.day}: ${kcal.round()} kkal',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSelectDate(normalized);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                SizedBox(
                                  height: barAreaHeight,
                                  width: 14,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: <Widget>[
                                      Container(
                                        width: 14,
                                        height: barAreaHeight,
                                        decoration: BoxDecoration(
                                          color: colors.mutedSurface,
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: disableAnimations
                                            ? Duration.zero
                                            : CalSnapMotion.transitionDuration,
                                        curve: CalSnapMotion.easeOut,
                                        width: 14,
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  shortWeekdayLabel(normalized),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? scheme.onSurface
                                        : colors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var x = 0.0;
    while (x < size.width) {
      final endX = math.min(x + dashWidth, size.width);
      canvas.drawLine(Offset(x, 0), Offset(endX, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
