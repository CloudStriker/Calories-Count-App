import 'dart:typed_data';

import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/screens/settings_screen.dart';
import 'package:calsnap/services/food_analyzer.dart';
import 'package:calsnap/state/meal_log_controller.dart';
import 'package:calsnap/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class ReviewMealScreen extends StatefulWidget {
  const ReviewMealScreen({
    super.key,
    required this.controller,
    required this.imageBytes,
    required this.mimeType,
    this.initialEatenAt,
  });

  final MealLogController controller;
  final Uint8List imageBytes;
  final String mimeType;
  final DateTime? initialEatenAt;

  @override
  State<ReviewMealScreen> createState() => _ReviewMealScreenState();
}

class _ReviewMealScreenState extends State<ReviewMealScreen> {
  late final TextEditingController _noteController;
  late final TextEditingController _titleController;
  late final DateTime _eatenAt;
  late MealCategory _category;

  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  bool _isSaving = false;
  String? _analysisError;
  String? _analysisErrorCode;
  String? _aiNotes;
  List<FoodItem> _items = <FoodItem>[];

  @override
  void initState() {
    super.initState();
    _eatenAt = widget.initialEatenAt ?? DateTime.now();
    _category = MealCategory.guessFromTime(_eatenAt);
    _noteController = TextEditingController();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _analysisErrorCode = null;
    });
    try {
      final result = await widget.controller.analyzePhoto(
        imageBytes: widget.imageBytes,
        mimeType: widget.mimeType,
        userNote: _noteController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _titleController.text = result.mealTitle;
        _items = List<FoodItem>.from(result.items);
        _aiNotes = result.notes;
        _hasAnalyzed = true;
      });
    } on FoodAnalysisException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _analysisError = e.message;
        _analysisErrorCode = e.code;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _analysisError = 'Terjadi kesalahan saat menganalisis foto.';
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _startManualEntry() {
    setState(() {
      _hasAnalyzed = true;
      _analysisError = null;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = 'Makanan';
      }
      if (_items.isEmpty) {
        _items = const <FoodItem>[
          FoodItem(
            name: 'Makanan',
            portionLabel: '1 porsi',
            grams: 200,
            calories: 350,
            proteinGrams: 15,
            carbsGrams: 45,
            fatGrams: 10,
          ),
        ];
      }
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _editOrAddItem({int? index}) async {
    final existing = index == null ? null : _items[index];
    final edited = await showDialog<FoodItem>(
      context: context,
      builder: (_) => _FoodItemDialog(initial: existing),
    );
    if (edited == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _items = <FoodItem>[..._items, edited];
      } else {
        final next = List<FoodItem>.from(_items);
        next[index] = edited;
        _items = next;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      final next = List<FoodItem>.from(_items);
      next.removeAt(index);
      _items = next;
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final title = _titleController.text.trim().isEmpty
          ? _items.first.name
          : _titleController.text.trim();
      final saved = await widget.controller.saveMeal(
        eatenAt: _eatenAt,
        category: _category,
        title: title,
        items: _items,
        photoBytes: widget.imageBytes,
        userNote: _noteController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      final String feedback = switch (saved.syncStatus) {
        HealthSyncStatus.synced =>
          'Tersimpan dan tersinkron ke Health Connect.',
        HealthSyncStatus.failed =>
          'Tersimpan lokal, tapi gagal sinkron ke Health Connect.',
        HealthSyncStatus.skipped =>
          'Tersimpan lokal (Health Connect tidak aktif).',
        HealthSyncStatus.pending => 'Tersimpan lokal.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedback)),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan catatan makanan. Coba lagi.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasAnalyzed ? 'Periksa & Simpan' : 'Analisis Makanan'),
        actions: <Widget>[
          if (_hasAnalyzed)
            TextButton.icon(
              onPressed: _isAnalyzing
                  ? null
                  : () => setState(() => _hasAnalyzed = false),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Analisis Ulang'),
            ),
        ],
      ),
      body: SafeArea(
        child: _hasAnalyzed ? _buildReviewBody() : _buildPreAnalysisBody(),
      ),
      bottomNavigationBar: _hasAnalyzed ? _buildBottomSaveBar() : null,
    );
  }

  Widget _buildPreAnalysisBody() {
    final colors = context.calColors;
    final showSettingsShortcut = _analysisErrorCode == 'missing_api_key' ||
        _analysisErrorCode == 'invalid_api_key' ||
        _analysisErrorCode == 'model_not_found';

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _PhotoPreview(bytes: widget.imageBytes, maxHeight: 280),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Catatan tambahan (opsional)',
                hintText: 'Contoh: nasi setengah, ayam tanpa kulit',
              ),
            ),
            const SizedBox(height: 16),
            if (_analysisError != null) ...<Widget>[
              Card(
                color: colors.errorBg,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          ExcludeSemantics(
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: colors.errorFg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _analysisError!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.errorFg),
                            ),
                          ),
                        ],
                      ),
                      if (showSettingsShortcut) ...<Widget>[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.errorFg,
                              side: BorderSide(color: colors.errorFg),
                            ),
                            onPressed: _openSettings,
                            icon: const Icon(Icons.settings_rounded, size: 18),
                            label: const Text('Buka Pengaturan'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isAnalyzing ? 'Menganalisis Foto...' : 'Analisis Kalori',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isAnalyzing ? null : _startManualEntry,
                child: const Text('Isi Manual Tanpa AI'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExpanded = constraints.maxWidth >= 600;
        if (isExpanded) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 340,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _PhotoPreview(bytes: widget.imageBytes, maxHeight: 200),
                    const SizedBox(height: 14),
                    _buildMetadataFields(),
                    const SizedBox(height: 14),
                    _buildTotalsSummary(),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: context.calColors.border),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: _buildItemsSection(),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _PhotoPreview(bytes: widget.imageBytes, maxHeight: 200),
            const SizedBox(height: 14),
            _buildMetadataFields(),
            const SizedBox(height: 14),
            _buildTotalsSummary(),
            const SizedBox(height: 16),
            ..._buildItemsSection(),
          ],
        );
      },
    );
  }

  Widget _buildMetadataFields() {
    final colors = context.calColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Nama Hidangan',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Waktu Makan',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MealCategory.values.map((category) {
            return ChoiceChip(
              label: Text(category.labelId),
              selected: _category == category,
              onSelected: (_) => setState(() => _category = category),
            );
          }).toList(),
        ),
        if (_aiNotes != null && _aiNotes!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.mutedSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              _aiNotes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalsSummary() {
    final totals = DailyTotals.fromItems(_items);
    final theme = Theme.of(context);
    final colors = context.calColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Total Estimasi',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.mutedText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${totals.calories.round()} kkal',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Protein ${totals.proteinGrams.round()}g · Karbo ${totals.carbsGrams.round()}g · Lemak ${totals.fatGrams.round()}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemsSection() {
    final colors = context.calColors;
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Komponen Makanan (${_items.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _editOrAddItem(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Tambah Item'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_items.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Belum ada item. Ketuk Tambah Item untuk memasukkan makanan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.mutedText,
                  ),
            ),
          ),
        ),
      for (var i = 0; i < _items.length; i++) ...<Widget>[
        _EditableItemCard(
          item: _items[i],
          onEdit: () => _editOrAddItem(index: i),
          onDelete: () => _removeItem(i),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _buildBottomSaveBar() {
    final colors = context.calColors;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_items.isEmpty || _isSaving) ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan & Sinkron'),
            ),
          ),
        ),
      ),
    );
  }

}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.bytes,
    required this.maxHeight,
  });

  final Uint8List bytes;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          width: double.infinity,
          color: context.calColors.mutedSurface,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            semanticLabel: 'Pratinjau foto makanan',
            errorBuilder: (_, _, _) => const SizedBox(
              height: 140,
              child: Center(
                child: Icon(Icons.broken_image_outlined, size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableItemCard extends StatelessWidget {
  const _EditableItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.calColors;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.portionLabel} (${item.grams.round()} g) · ${item.calories.round()} kkal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'P ${item.proteinGrams.round()}g · K ${item.carbsGrams.round()}g · L ${item.fatGrams.round()}g',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit item',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Hapus item',
                icon: Icon(Icons.delete_outline_rounded, color: colors.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodItemDialog extends StatefulWidget {
  const _FoodItemDialog({this.initial});

  final FoodItem? initial;

  @override
  State<_FoodItemDialog> createState() => _FoodItemDialogState();
}

class _FoodItemDialogState extends State<_FoodItemDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _portion;
  late final TextEditingController _grams;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _portion = TextEditingController(text: item?.portionLabel ?? '1 porsi');
    _grams = TextEditingController(text: _fmtNum(item?.grams ?? 100));
    _calories = TextEditingController(text: _fmtNum(item?.calories ?? 200));
    _protein = TextEditingController(text: _fmtNum(item?.proteinGrams ?? 10));
    _carbs = TextEditingController(text: _fmtNum(item?.carbsGrams ?? 25));
    _fat = TextEditingController(text: _fmtNum(item?.fatGrams ?? 5));
  }

  String _fmtNum(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _name.dispose();
    _portion.dispose();
    _grams.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  String? _validateNonNegative(String? raw) {
    final parsed = double.tryParse((raw ?? '').trim().replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return 'Angka >= 0';
    }
    return null;
  }

  double _parseNum(TextEditingController c) =>
      double.parse(c.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Tambah Item' : 'Edit Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama Makanan'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _portion,
                decoration: const InputDecoration(labelText: 'Ukuran Porsi'),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _grams,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Gram (g)'),
                      validator: _validateNonNegative,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _calories,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Kalori'),
                      validator: _validateNonNegative,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _protein,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                      validator: _validateNonNegative,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      controller: _carbs,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Karbo (g)'),
                      validator: _validateNonNegative,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      controller: _fat,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Lemak (g)'),
                      validator: _validateNonNegative,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.of(context).pop(
              FoodItem(
                name: _name.text.trim(),
                portionLabel: _portion.text.trim().isEmpty
                    ? '1 porsi'
                    : _portion.text.trim(),
                grams: _parseNum(_grams),
                calories: _parseNum(_calories),
                proteinGrams: _parseNum(_protein),
                carbsGrams: _parseNum(_carbs),
                fatGrams: _parseNum(_fat),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
