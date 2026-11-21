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
          content: Text('Gagal membuka foto. Pastikan izin kamera atau galeri diizinkan.'),
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
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    letterSpacing: -0.4,
                  ),
                ),
                actions: <Widget>[
                  IconButton(
                    onPressed: _openSettings,
                    tooltip: 'Pengaturan',
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ),
              body: SafeArea(
                child: isExpanded
                    ? _buildExpandedBody()
                    : _buildCompactBody(),
              ),
              bottomNavigationBar: isExpanded ? null : _buildBottomCaptureBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactBody() {
    final meals = widget.controller.meals;
    return ListView(
      key: const ValueKey<String>('home-compact-layout'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: <Widget>[
        _DateSwitcherRow(
          selectedDate: widget.controller.selectedDate,
          onSelectDate: widget.controller.selectDate,
        ),
        const SizedBox(height: 12),
        ..._buildSetupBanners(),
        DailySummaryCard(
          totals: widget.controller.dailyTotals,
          dailyGoal: widget.controller.settings.dailyCalorieGoal,
        ),
        const SizedBox(height: 18),
        _buildMealListHeader(meals.length),
        const SizedBox(height: 10),
        ..._buildMealListContent(meals),
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
          width: 356,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _DateSwitcherRow(
                selectedDate: widget.controller.selectedDate,
                onSelectDate: widget.controller.selectDate,
              ),
              const SizedBox(height: 12),
              DailySummaryCard(
                totals: widget.controller.dailyTotals,
                dailyGoal: widget.controller.settings.dailyCalorieGoal,
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
                  onPressed: () =>
                      widget.controller.selectDate(widget.controller.selectedDate),
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
          onRetrySync: () => _retrySync(meal),
          onDelete: () => _confirmDelete(meal),
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
          text: 'Masukkan Gemini API key di Pengaturan untuk mulai menganalisis foto.',
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
          text: 'Hubungkan Health Connect agar catatan masuk ke Samsung Health.',
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

  Widget _buildBottomCaptureBar() {
    final colors = context.calColors;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _CaptureActionButtons(
            isBusy: _isPickingPhoto,
            onCamera: () => _pickAndAnalyze(ImageSource.camera),
            onGallery: () => _pickAndAnalyze(ImageSource.gallery),
          ),
        ),
      ),
    );
  }
}

class _DateSwitcherRow extends StatelessWidget {
  const _DateSwitcherRow({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final today = startOfDay(DateTime.now());
    final canGoForward = !isSameDay(selectedDate, today);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final dateLabel = formatRelativeDay(selectedDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onSelectDate(
                  selectedDate.subtract(const Duration(days: 1)),
                );
              },
              tooltip: 'Hari sebelumnya',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: disableAnimations
                    ? Duration.zero
                    : CalSnapMotion.transitionDuration,
                switchInCurve: CalSnapMotion.easeOut,
                switchOutCurve: CalSnapMotion.easeOut,
                transitionBuilder: (child, animation) {
                  if (disableAnimations) {
                    return child;
                  }
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  dateLabel,
                  key: ValueKey<String>(dateLabel),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              onPressed: canGoForward
                  ? () {
                      HapticFeedback.selectionClick();
                      onSelectDate(
                        selectedDate.add(const Duration(days: 1)),
                      );
                    }
                  : null,
              tooltip: 'Hari berikutnya',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
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
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
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
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: TactilePress(
            disabled: isBusy,
            enableHaptic: true,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galeri'),
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
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
