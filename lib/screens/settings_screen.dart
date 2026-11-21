import 'package:calsnap/services/health_sync_service.dart';
import 'package:calsnap/services/settings_store.dart';
import 'package:calsnap/state/meal_log_controller.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
  });

  final MealLogController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late final TextEditingController _goalController;

  bool _obscureKey = true;
  bool _isSaving = false;
  bool _isConnectingHealth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = widget.controller.settings;
    _apiKeyController = TextEditingController(text: settings.apiKey ?? '');
    _modelController = TextEditingController(text: settings.modelName);
    _goalController = TextEditingController(
      text: settings.dailyCalorieGoal.toString(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyController.dispose();
    _modelController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshHealthStatus();
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final goal = int.parse(_goalController.text.trim());
      await widget.controller.saveSettings(
        apiKey: _apiKeyController.text.trim(),
        modelName: _modelController.text.trim(),
        dailyCalorieGoal: goal,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan tersimpan.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan pengaturan ke penyimpanan aman.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _clearKey() async {
    try {
      await widget.controller.clearApiKey();
      if (!mounted) {
        return;
      }
      _apiKeyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key dihapus dari perangkat.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus API key.')),
      );
    }
  }

  Future<void> _handleHealthAction() async {
    setState(() => _isConnectingHealth = true);
    try {
      final granted = await widget.controller.connectHealthConnect();
      if (!mounted) {
        return;
      }
      final availability = widget.controller.healthAvailability;
      final String message;
      if (availability == HealthAvailability.needsInstall) {
        message = 'Silakan pasang Health Connect, lalu kembali ke layar ini.';
      } else if (availability == HealthAvailability.unavailable) {
        message = 'Health Connect tidak tersedia di profil atau perangkat ini.';
      } else if (granted) {
        message = 'Health Connect terhubung.';
      } else {
        message =
            'Izin tulis nutrisi belum diberikan. Anda bisa mengaktifkannya di Health Connect.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnectingHealth = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final settings = widget.controller.settings;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      _SectionCard(
                        title: 'Gemini API',
                        subtitle:
                            'Key disimpan terenkripsi hanya di HP Anda dan tidak pernah masuk ke kode aplikasi.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _KeyStatusRow(hasApiKey: settings.hasApiKey),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _apiKeyController,
                              obscureText: _obscureKey,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: InputDecoration(
                                labelText: 'Gemini API Key',
                                hintText: 'AIza...',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureKey = !_obscureKey,
                                  ),
                                  tooltip: _obscureKey
                                      ? 'Tampilkan API key'
                                      : 'Sembunyikan API key',
                                  icon: Icon(
                                    _obscureKey
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                            ),
                            if (settings.hasApiKey) ...<Widget>[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _clearKey,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Hapus Key'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              'Model Gemini',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _modelController,
                              builder: (context, value, _) {
                                final current = value.text.trim();
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: presetGeminiModels.map((model) {
                                    return ChoiceChip(
                                      label: Text(model),
                                      selected: current == model,
                                      onSelected: (_) {
                                        _modelController.text = model;
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _modelController,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'ID Model Aktif',
                                helperText:
                                    'Bisa diganti kapan saja tanpa rebuild APK.',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama model tidak boleh kosong.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Target Kalori Harian',
                        child: TextFormField(
                          controller: _goalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Target Harian (kkal)',
                            suffixText: 'kkal',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null ||
                                parsed < 500 ||
                                parsed > 10000) {
                              return 'Masukkan angka antara 500 sampai 10.000 kkal.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveSettings,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: const Text('Simpan Pengaturan'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Samsung Health & Health Connect',
                        subtitle:
                            'CalSnap menulis data nutrisi ke Health Connect agar otomatis masuk ke Food Tracker Samsung Health.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _HealthStatusRow(
                              availability: widget.controller.healthAvailability,
                              hasPermission:
                                  widget.controller.hasHealthPermission,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                FilledButton.icon(
                                  onPressed: _isConnectingHealth
                                      ? null
                                      : _handleHealthAction,
                                  icon: Icon(
                                    widget.controller.healthAvailability ==
                                            HealthAvailability.needsInstall
                                        ? Icons.download_rounded
                                        : Icons.link_rounded,
                                  ),
                                  label: Text(
                                    widget.controller.healthAvailability ==
                                            HealthAvailability.needsInstall
                                        ? 'Pasang Health Connect'
                                        : widget.controller.hasHealthPermission
                                            ? 'Cek Ulang Izin'
                                            : 'Hubungkan Health Connect',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      widget.controller.refreshHealthStatus,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Segarkan'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.mutedSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Aktifkan di Samsung Health (cukup sekali):',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '1. Buka Samsung Health > Pengaturan > Health Connect.\n'
                                    '2. Aktifkan izin Baca (Read) untuk Nutrisi (Nutrition).\n'
                                    '3. Aktifkan Sync with Samsung Cloud agar catatan muncul otomatis di Food Tracker.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(height: 1.45),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Privasi Data',
                        child: Text(
                          'Foto makanan dan riwayat kalori disimpan secara lokal di HP Anda. Foto hanya dikirim ke Gemini API saat Anda menekan Analisis Kalori.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.mutedText,
                                    height: 1.45,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _KeyStatusRow extends StatelessWidget {
  const _KeyStatusRow({required this.hasApiKey});

  final bool hasApiKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final bg = hasApiKey ? colors.successBg : colors.warningBg;
    final fg = hasApiKey ? colors.successFg : colors.warningFg;
    final icon =
        hasApiKey ? Icons.verified_user_rounded : Icons.vpn_key_off_rounded;
    final text = hasApiKey
        ? 'API key tersimpan aman di perangkat'
        : 'API key belum diisi';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(child: Icon(icon, size: 18, color: fg)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _HealthStatusRow extends StatelessWidget {
  const _HealthStatusRow({
    required this.availability,
    required this.hasPermission,
  });

  final HealthAvailability availability;
  final bool hasPermission;

  @override
  Widget build(BuildContext context) {
    final colors = context.calColors;
    final (IconData icon, String label, Color bg, Color fg) = switch (
        availability) {
      HealthAvailability.available when hasPermission => (
          Icons.check_circle_rounded,
          'Terhubung (izin tulis nutrisi aktif)',
          colors.successBg,
          colors.successFg,
        ),
      HealthAvailability.available => (
          Icons.link_off_rounded,
          'Health Connect siap, izin tulis belum aktif',
          colors.warningBg,
          colors.warningFg,
        ),
      HealthAvailability.needsInstall => (
          Icons.download_for_offline_rounded,
          'Health Connect perlu dipasang atau diperbarui',
          colors.warningBg,
          colors.warningFg,
        ),
      HealthAvailability.unavailable => (
          Icons.info_outline_rounded,
          'Health Connect tidak tersedia di perangkat ini',
          colors.errorBg,
          colors.errorFg,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(child: Icon(icon, size: 18, color: fg)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
