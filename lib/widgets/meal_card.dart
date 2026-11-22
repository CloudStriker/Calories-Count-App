import 'dart:io';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:calsnap/widgets/tactile_press.dart';
import 'package:material_ui/material_ui.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onRetrySync,
  });

  final MealEntry meal;
  final VoidCallback onTap;
  final VoidCallback onRetrySync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.calColors;
    final isDark = theme.brightness == Brightness.dark;
    final path = meal.photoPath;
    final hasFile = path != null && path.isNotEmpty && File(path).existsSync();

    return TactilePress(
      enableHaptic: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: isDark
              ? BorderSide(color: Colors.white.withValues(alpha: 0.06))
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: hasFile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            semanticLabel: 'Foto ${meal.title}',
                            errorBuilder: (_, _, _) => Container(
                              color: colors.mutedSurface,
                              child: Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  size: 32,
                                  color: colors.mutedText,
                                ),
                              ),
                            ),
                          ),
                          if (isDark)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const <double>[0.45, 1.0],
                                  colors: <Color>[
                                    Colors.transparent,
                                    theme.colorScheme.surface,
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xBD0A0A0A),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${meal.category.labelId} · ${formatTimeHm(meal.eatenAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: tabularFigures,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildTitleAndCaloriesRow(context),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(child: _MacroDotsLine(meal: meal)),
                              const SizedBox(width: 8),
                              _CompactSyncIndicator(status: meal.syncStatus),
                            ],
                          ),
                          if (meal.items.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 10),
                            _MealItemPreviewChips(items: meal.items),
                          ],
                          if (meal.syncStatus == HealthSyncStatus.failed)
                            ..._buildRetryStrip(context),
                        ],
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.mutedSurface,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${meal.category.labelId} · ${formatTimeHm(meal.eatenAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.mutedText,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: tabularFigures,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CompactSyncIndicator(status: meal.syncStatus),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildTitleAndCaloriesRow(context),
                      const SizedBox(height: 8),
                      _MacroDotsLine(meal: meal),
                      if (meal.items.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        _MealItemPreviewChips(items: meal.items),
                      ],
                      if (meal.syncStatus == HealthSyncStatus.failed)
                        ..._buildRetryStrip(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTitleAndCaloriesRow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(
          child: Text(
            meal.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${meal.totalCalories.round()} kkal',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            fontFeatures: tabularFigures,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRetryStrip(BuildContext context) {
    final colors = context.calColors;
    final message = (meal.syncError != null && meal.syncError!.isNotEmpty)
        ? meal.syncError!
        : 'Gagal sinkron ke Health Connect';
    return <Widget>[
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.errorBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.errorFg,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colors.errorFg,
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: onRetrySync,
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    ];
  }
}

class _MealItemPreviewChips extends StatelessWidget {
  const _MealItemPreviewChips({required this.items});

  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final visible = items.take(3).toList();
    final remaining = items.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final item in visible)
          Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.mutedSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: colors.mutedText,
              ),
            ),
          ),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.mutedSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remaining lainnya',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.mutedText,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
      ],
    );
  }
}

class _MacroDotsLine extends StatelessWidget {
  const _MacroDotsLine({required this.meal});

  final MealEntry meal;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final valueStyle = TextStyle(
      fontSize: 12.5,
      color: colors.mutedText,
      fontWeight: FontWeight.w600,
      fontFeatures: tabularFigures,
    );
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'P',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.proteinColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' ${meal.totalProtein.round()}g   ',
            style: valueStyle,
          ),
          TextSpan(
            text: 'K',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.carbsColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' ${meal.totalCarbs.round()}g   ',
            style: valueStyle,
          ),
          TextSpan(
            text: 'L',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.fatColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' ${meal.totalFat.round()}g',
            style: valueStyle,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CompactSyncIndicator extends StatelessWidget {
  const _CompactSyncIndicator({required this.status});

  final HealthSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final (IconData icon, String label, Color iconColor, Color textColor) =
        switch (status) {
      HealthSyncStatus.synced => (
          Icons.check_circle_rounded,
          'Health',
          colors.successFg,
          colors.mutedText,
        ),
      HealthSyncStatus.failed => (
          Icons.error_outline_rounded,
          'Gagal',
          colors.errorFg,
          colors.errorFg,
        ),
      HealthSyncStatus.pending => (
          Icons.schedule_rounded,
          'Tertunda',
          colors.warningFg,
          colors.warningFg,
        ),
      HealthSyncStatus.skipped => (
          Icons.save_alt_rounded,
          'Lokal',
          colors.mutedText,
          colors.mutedText,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
