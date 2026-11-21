import 'dart:io';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:material_ui/material_ui.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onRetrySync,
    required this.onDelete,
  });

  final MealEntry meal;
  final VoidCallback onRetrySync;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.calColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _MealThumbnail(photoPath: meal.photoPath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        meal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            '${meal.category.labelId} · ${formatTimeHm(meal.eatenAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${meal.totalCalories.round()} kkal',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'P ${meal.totalProtein.round()}g · K ${meal.totalCarbs.round()}g · L ${meal.totalFat.round()}g',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Hapus catatan',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
            if (meal.items.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                meal.items.map((item) => '${item.name} (${item.calories.round()} kkal)').join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _SyncStatusBadge(status: meal.syncStatus),
                if (meal.syncStatus == HealthSyncStatus.failed ||
                    meal.syncStatus == HealthSyncStatus.pending)
                  TextButton.icon(
                    onPressed: onRetrySync,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      meal.syncStatus == HealthSyncStatus.failed
                          ? 'Coba Lagi'
                          : 'Sinkronkan',
                    ),
                  ),
              ],
            ),
            if (meal.syncStatus == HealthSyncStatus.failed &&
                meal.syncError != null &&
                meal.syncError!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                meal.syncError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.errorFg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealThumbnail extends StatelessWidget {
  const _MealThumbnail({required this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final path = photoPath;
    final hasFile = path != null && path.isNotEmpty && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: colors.mutedSurface,
        child: hasFile
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                semanticLabel: 'Foto makanan',
                errorBuilder: (_, _, _) => _fallbackIcon(context),
              )
            : _fallbackIcon(context),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.restaurant_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 28,
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  const _SyncStatusBadge({required this.status});

  final HealthSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final (IconData icon, String label, Color bg, Color fg) = switch (status) {
      HealthSyncStatus.synced => (
          Icons.check_circle_rounded,
          'Tersinkron ke Health Connect',
          colors.successBg,
          colors.successFg,
        ),
      HealthSyncStatus.failed => (
          Icons.error_outline_rounded,
          'Gagal sinkron',
          colors.errorBg,
          colors.errorFg,
        ),
      HealthSyncStatus.pending => (
          Icons.schedule_rounded,
          'Belum sinkron',
          colors.warningBg,
          colors.warningFg,
        ),
      HealthSyncStatus.skipped => (
          Icons.save_alt_rounded,
          'Tersimpan lokal',
          colors.mutedSurface,
          colors.mutedText,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
