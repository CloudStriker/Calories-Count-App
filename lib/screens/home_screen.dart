import 'dart:io';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/screens/review_meal_screen.dart';
import 'package:calsnap/screens/settings_screen.dart';
import 'package:calsnap/services/health_sync_service.dart';
import 'package:calsnap/state/meal_log_controller.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:calsnap/widgets/daily_summary_card.dart';
import 'package:calsnap/widgets/meal_card.dart';
import 'package:calsnap/widgets/tactile_press.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class PickedPhotoData {
  const PickedPhotoData({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;
}

typedef PhotoPickerFn = Future<PickedPhotoData?> Function(ImageSource source);

Future<PickedPhotoData?> defaultImagePicker(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 78,
  );
  if (picked == null) {
    return null;
  }
  final bytes = await picked.readAsBytes();
  final mime = picked.mimeType ?? _inferMimeType(picked.path);
  return PickedPhotoData(bytes: bytes, mimeType: mime);
}

String _inferMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.heic')) {
    return 'image/heic';
  }
  if (lower.endsWith('.heif')) {
    return 'image/heif';
  }
  return 'image/jpeg';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    this.photoPicker = defaultImagePicker,
  });

  final MealLogController controller;
  final PhotoPickerFn photoPicker;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshHealthStatus();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _pickDate() async {
    final today = startOfDay(DateTime.now());
    final selected = widget.controller.selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: selected.isAfter(today) ? today : selected,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null && mounted) {
      HapticFeedback.selectionClick();
      await widget.controller.selectDate(picked);
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    if (_isPickingPhoto) {
      return;
    }
    setState(() => _isPickingPhoto = true);
    try {
      final photo = await widget.photoPicker(source);
      if (photo == null || !mounted) {
        return;
      }
      final now = DateTime.now();
      final selected = widget.controller.selectedDate;
      final eatenAt = isSameDay(selected, now)
          ? now
          : DateTime(
              selected.year,
              selected.month,
              selected.day,
              now.hour,
              now.minute,
            );
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReviewMealScreen(
            controller: widget.controller,
            imageBytes: photo.bytes,
            mimeType: photo.mimeType,
            initialEatenAt: eatenAt,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal membuka foto. Pastikan izin kamera atau galeri diizinkan.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _retrySync(MealEntry meal) async {
    final updated = await widget.controller.retryHealthSync(meal);
    if (!mounted) {
      return;
    }
    final message = updated.syncStatus == HealthSyncStatus.synced
        ? 'Berhasil sinkron ke Health Connect.'
        : (updated.syncError ?? 'Belum berhasil sinkron ke Health Connect.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmDelete(MealEntry meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text(
          'Hapus "${meal.title}" dari riwayat lokal? Data yang sudah dikirim ke Health Connect tidak ikut terhapus otomatis.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deleteMeal(meal);
    }
  }

  Future<void> _openMealDetail(MealEntry meal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _MealDetailSheet(
        meal: meal,
        onRetrySync: () {
          Navigator.of(sheetContext).pop();
          _retrySync(meal);
        },
        onDelete: () {
          Navigator.of(sheetContext).pop();
          _confirmDelete(meal);
        },
      ),
    );
  }

  String _summaryEyebrow() {
    final selected = widget.controller.selectedDate;
    if (isSameDay(selected, DateTime.now())) {
      return 'KALORI HARI INI';
    }
    return formatRelativeDay(selected).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded = constraints.maxWidth >= 600;
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'CalSnap',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.6,
                  ),
                ),
                actions: <Widget>[
                  IconButton(
                    onPressed: _pickDate,
                    tooltip: 'Pilih tanggal',
                    icon: const Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  IconButton(
                    onPressed: _openSettings,
                    tooltip: 'Pengaturan',
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              body: SafeArea(
                child: isExpanded
                    ? _buildExpandedBody()
                    : _buildCompactBody(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactBody() {
    final meals = widget.controller.meals;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      key: const ValueKey<String>('home-compact-layout'),
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 108),
          children: <Widget>[
            _WeekDateStrip(
              selectedDate: widget.controller.selectedDate,
              onSelectDate: widget.controller.selectDate,
            ),
            const SizedBox(height: 12),
            ..._buildSetupBanners(),
            DailySummaryCard(
              totals: widget.controller.dailyTotals,
              dailyGoal: widget.controller.settings.dailyCalorieGoal,
              eyebrowLabel: _summaryEyebrow(),
            ),
            const SizedBox(height: 20),
            _buildMealListHeader(meals.length),
            const SizedBox(height: 10),
            ..._buildMealListContent(meals),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    scaffoldBg.withValues(alpha: 0),
                    scaffoldBg,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: _CaptureActionButtons(
            isBusy: _isPickingPhoto,
            onCamera: () => _pickAndAnalyze(ImageSource.camera),
            onGallery: () => _pickAndAnalyze(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedBody() {
    final meals = widget.controller.meals;
    final colors = context.calColors;
    return Row(
      key: const ValueKey<String>('home-expanded-layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 364,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              _WeekDateStrip(
                selectedDate: widget.controller.selectedDate,
                onSelectDate: widget.controller.selectDate,
              ),
              const SizedBox(height: 12),
              DailySummaryCard(
                totals: widget.controller.dailyTotals,
                dailyGoal: widget.controller.settings.dailyCalorieGoal,
                eyebrowLabel: _summaryEyebrow(),
              ),
              const SizedBox(height: 14),
              ..._buildSetupBanners(),
              _CaptureActionButtons(
                isBusy: _isPickingPhoto,
                onCamera: () => _pickAndAnalyze(ImageSource.camera),
                onGallery: () => _pickAndAnalyze(ImageSource.gallery),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: colors.border),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _buildMealListHeader(meals.length),
                  const SizedBox(height: 12),
                  ..._buildMealListContent(meals),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMealListContent(List<MealEntry> meals) {
    final error = widget.controller.errorMessage;
    if (widget.controller.isLoading) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (error != null) {
      final colors = context.calColors;
      return <Widget>[
        Card(
          color: colors.errorBg,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: Icon(Icons.error_outline_rounded, color: colors.errorFg),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.errorFg,
                        ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: colors.errorFg),
                  onPressed: () => widget.controller
                      .selectDate(widget.controller.selectedDate),
                  child: const Text('Muat Ulang'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (meals.isEmpty) {
      return const <Widget>[_EmptyMealsCard()];
    }
    return <Widget>[
      for (final meal in meals) ...<Widget>[
        MealCard(
          meal: meal,
          onTap: () => _openMealDetail(meal),
          onRetrySync: () => _retrySync(meal),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildMealListHeader(int count) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Catatan Makan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          '$count item',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.calColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  List<Widget> _buildSetupBanners() {
    final banners = <Widget>[];
    final controller = widget.controller;
    final colors = context.calColors;

    if (!controller.settings.hasApiKey) {
      banners.add(
        _SetupBanner(
          icon: Icons.key_rounded,
          text:
              'Masukkan Gemini API key di Pengaturan untuk mulai menganalisis foto.',
          actionLabel: 'Pengaturan',
          background: colors.warningBg,
          foreground: colors.warningFg,
          onAction: _openSettings,
        ),
      );
    }

    if (controller.healthAvailability == HealthAvailability.available &&
        !controller.hasHealthPermission) {
      banners.add(
        _SetupBanner(
          icon: Icons.favorite_border_rounded,
          text:
              'Hubungkan Health Connect agar catatan masuk ke Samsung Health.',
          actionLabel: 'Hubungkan',
          background: colors.mutedSurface,
          foreground: Theme.of(context).colorScheme.onSurface,
          onAction: controller.connectHealthConnect,
        ),
      );
    } else if (controller.healthAvailability == HealthAvailability.needsInstall) {
      banners.add(
        _SetupBanner(
          icon: Icons.download_rounded,
          text: 'Pasang Health Connect untuk sinkronisasi ke Samsung Health.',
          actionLabel: 'Pasang',
          background: colors.warningBg,
          foreground: colors.warningFg,
          onAction: controller.connectHealthConnect,
        ),
      );
    }

    if (banners.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      for (final banner in banners) ...<Widget>[
        banner,
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  void _shiftWeek(int deltaDays) {
    final today = startOfDay(DateTime.now());
    final candidate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + deltaDays,
    );
    final target = candidate.isAfter(today) ? today : candidate;
    if (!isSameDay(target, selectedDate)) {
      HapticFeedback.selectionClick();
      onSelectDate(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.calColors;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final today = startOfDay(DateTime.now());
    final days = buildWeekWindow(selectedDate, now: today);

    return GestureDetector(
      key: const ValueKey<String>('home-week-strip'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 250) {
          _shiftWeek(-7);
        } else if (velocity < -250) {
          _shiftWeek(7);
        }
      },
      child: Row(
        children: days.map((day) {
          final isSelected = isSameDay(day, selectedDate);
          final isToday = isSameDay(day, today);
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '${shortWeekdayLabel(day)} ${day.day}',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelectDate(day);
                },
                child: AnimatedContainer(
                  duration: disableAnimations
                      ? Duration.zero
                      : CalSnapMotion.transitionDuration,
                  curve: CalSnapMotion.easeOut,
                  constraints: const BoxConstraints(minHeight: 54),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        shortWeekdayLabel(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? scheme.onPrimary : colors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isSelected ? scheme.onPrimary : scheme.onSurface,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 4,
                        child: isToday && !isSelected
                            ? Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CaptureActionButtons extends StatelessWidget {
  const _CaptureActionButtons({
    required this.isBusy,
    required this.onCamera,
    required this.onGallery,
  });

  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.calColors;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: isDark ? Border.all(color: colors.border) : null,
        boxShadow: isDark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 11,
            child: TactilePress(
              disabled: isBusy,
              enableHaptic: true,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onCamera,
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Kamera'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 9,
            child: TactilePress(
              disabled: isBusy,
              enableHaptic: true,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  minimumSize: const Size(48, 52),
                  shape: const StadiumBorder(),
                ),
                onPressed: isBusy ? null : onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeri'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealDetailSheet extends StatelessWidget {
  const _MealDetailSheet({
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
    final scheme = theme.colorScheme;
    final colors = context.calColors;
    final path = meal.photoPath;
    final hasFile = path != null && path.isNotEmpty && File(path).existsSync();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (hasFile) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    semanticLabel: 'Foto ${meal.title}',
                    errorBuilder: (_, _, _) => Container(
                      color: colors.mutedSurface,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: colors.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              meal.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${meal.category.labelId} · ${formatTimeHm(meal.eatenAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w500,
                fontFeatures: tabularFigures,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${meal.totalCalories.round()} kkal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: scheme.onSurface,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                MacroPill(
                  label: 'P ${meal.totalProtein.round()}g',
                  accentColor: colors.proteinColor,
                ),
                MacroPill(
                  label: 'K ${meal.totalCarbs.round()}g',
                  accentColor: colors.carbsColor,
                ),
                MacroPill(
                  label: 'L ${meal.totalFat.round()}g',
                  accentColor: colors.fatColor,
                ),
              ],
            ),
            if (meal.userNote != null && meal.userNote!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.mutedSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  meal.userNote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ),
            ],
            if (meal.items.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Text(
                'Komponen Makanan',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in meal.items) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.mutedSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.portionLabel} (${item.grams.round()} g)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '${item.calories.round()} kkal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'P ${item.proteinGrams.round()} · K ${item.carbsGrams.round()} · L ${item.fatGrams.round()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.mutedText,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 10),
            _DetailSyncCard(meal: meal, onRetrySync: onRetrySync),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: colors.errorFg,
                ),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Hapus Catatan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSyncCard extends StatelessWidget {
  const _DetailSyncCard({
    required this.meal,
    required this.onRetrySync,
  });

  final MealEntry meal;
  final VoidCallback onRetrySync;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final (IconData icon, String label, Color bg, Color fg) = switch (
        meal.syncStatus) {
      HealthSyncStatus.synced => (
          Icons.check_circle_rounded,
          'Tersinkron ke Health Connect',
          colors.successBg,
          colors.successFg,
        ),
      HealthSyncStatus.failed => (
          Icons.error_outline_rounded,
          'Gagal sinkron ke Health Connect',
          colors.errorBg,
          colors.errorFg,
        ),
      HealthSyncStatus.pending => (
          Icons.schedule_rounded,
          'Belum tersinkron ke Health Connect',
          colors.warningBg,
          colors.warningFg,
        ),
      HealthSyncStatus.skipped => (
          Icons.save_alt_rounded,
          'Tersimpan lokal di perangkat',
          colors.mutedSurface,
          colors.mutedText,
        ),
    };
    final canRetry = meal.syncStatus == HealthSyncStatus.failed ||
        meal.syncStatus == HealthSyncStatus.pending;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ExcludeSemantics(child: Icon(icon, size: 18, color: fg)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg),
            ),
          ],
          if (canRetry) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: fg,
                side: BorderSide(color: fg.withValues(alpha: 0.4)),
                minimumSize: const Size(48, 42),
              ),
              onPressed: onRetrySync,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Sinkronkan Ulang'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  const _SetupBanner({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.background,
    required this.foreground,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final Color background;
  final Color foreground;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(icon, size: 20, color: foreground),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: foreground),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMealsCard extends StatelessWidget {
  const _EmptyMealsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        child: Column(
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 38,
                color: colors.mutedText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada catatan makan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Ambil foto makanan atau pilih dari galeri untuk mulai menghitung kalori.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
