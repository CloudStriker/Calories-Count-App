import 'package:material_ui/material_ui.dart';

@immutable
class CalSnapColors extends ThemeExtension<CalSnapColors> {
  const CalSnapColors({
    required this.border,
    required this.mutedSurface,
    required this.mutedText,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.successBg,
    required this.successFg,
    required this.warningBg,
    required this.warningFg,
    required this.errorBg,
    required this.errorFg,
  });

  final Color border;
  final Color mutedSurface;
  final Color mutedText;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;
  final Color successBg;
  final Color successFg;
  final Color warningBg;
  final Color warningFg;
  final Color errorBg;
  final Color errorFg;

  static const CalSnapColors light = CalSnapColors(
    border: Color(0xFFD1EAE0),
    mutedSurface: Color(0xFFF0F8F6),
    mutedText: Color(0xFF475569),
    proteinColor: Color(0xFF047857),
    carbsColor: Color(0xFFC2410C),
    fatColor: Color(0xFF0369A1),
    successBg: Color(0xFFD1FAE5),
    successFg: Color(0xFF065F46),
    warningBg: Color(0xFFFFEDD5),
    warningFg: Color(0xFF9A3412),
    errorBg: Color(0xFFFEE2E2),
    errorFg: Color(0xFF991B1B),
  );

  static const CalSnapColors dark = CalSnapColors(
    border: Color(0xFF233830),
    mutedSurface: Color(0xFF192A23),
    mutedText: Color(0xFF94A3B8),
    proteinColor: Color(0xFF34D399),
    carbsColor: Color(0xFFFB923C),
    fatColor: Color(0xFF38BDF8),
    successBg: Color(0xFF064E3B),
    successFg: Color(0xFFA7F3D0),
    warningBg: Color(0xFF431407),
    warningFg: Color(0xFFFED7AA),
    errorBg: Color(0xFF450A0A),
    errorFg: Color(0xFFFECACA),
  );

  @override
  CalSnapColors copyWith({
    Color? border,
    Color? mutedSurface,
    Color? mutedText,
    Color? proteinColor,
    Color? carbsColor,
    Color? fatColor,
    Color? successBg,
    Color? successFg,
    Color? warningBg,
    Color? warningFg,
    Color? errorBg,
    Color? errorFg,
  }) {
    return CalSnapColors(
      border: border ?? this.border,
      mutedSurface: mutedSurface ?? this.mutedSurface,
      mutedText: mutedText ?? this.mutedText,
      proteinColor: proteinColor ?? this.proteinColor,
      carbsColor: carbsColor ?? this.carbsColor,
      fatColor: fatColor ?? this.fatColor,
      successBg: successBg ?? this.successBg,
      successFg: successFg ?? this.successFg,
      warningBg: warningBg ?? this.warningBg,
      warningFg: warningFg ?? this.warningFg,
      errorBg: errorBg ?? this.errorBg,
      errorFg: errorFg ?? this.errorFg,
    );
  }

  @override
  CalSnapColors lerp(ThemeExtension<CalSnapColors>? other, double t) {
    if (other is! CalSnapColors) {
      return this;
    }
    return CalSnapColors(
      border: Color.lerp(border, other.border, t) ?? border,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t) ??
          mutedSurface,
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      proteinColor:
          Color.lerp(proteinColor, other.proteinColor, t) ?? proteinColor,
      carbsColor: Color.lerp(carbsColor, other.carbsColor, t) ?? carbsColor,
      fatColor: Color.lerp(fatColor, other.fatColor, t) ?? fatColor,
      successBg: Color.lerp(successBg, other.successBg, t) ?? successBg,
      successFg: Color.lerp(successFg, other.successFg, t) ?? successFg,
      warningBg: Color.lerp(warningBg, other.warningBg, t) ?? warningBg,
      warningFg: Color.lerp(warningFg, other.warningFg, t) ?? warningFg,
      errorBg: Color.lerp(errorBg, other.errorBg, t) ?? errorBg,
      errorFg: Color.lerp(errorFg, other.errorFg, t) ?? errorFg,
    );
  }
}

extension CalSnapThemeLookup on BuildContext {
  CalSnapColors get calColors =>
      Theme.of(this).extension<CalSnapColors>() ?? CalSnapColors.light;
}

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF047857),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD1FAE5),
      onPrimaryContainer: Color(0xFF064E3B),
      secondary: Color(0xFFC2410C),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFEDD5),
      onSecondaryContainer: Color(0xFF7C2D12),
      tertiary: Color(0xFF0369A1),
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFD1EAE0),
      outlineVariant: Color(0xFFE1F2ED),
      surfaceContainerHighest: Color(0xFFF0F8F6),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBg: const Color(0xFFECFDF5),
      ext: CalSnapColors.light,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF34D399),
      onPrimary: Color(0xFF052E16),
      primaryContainer: Color(0xFF064E3B),
      onPrimaryContainer: Color(0xFFD1FAE5),
      secondary: Color(0xFFFB923C),
      onSecondary: Color(0xFF2B1203),
      secondaryContainer: Color(0xFF431407),
      onSecondaryContainer: Color(0xFFFED7AA),
      tertiary: Color(0xFF38BDF8),
      onTertiary: Color(0xFF082F49),
      error: Color(0xFFF87171),
      onError: Color(0xFF2A0A0A),
      errorContainer: Color(0xFF450A0A),
      onErrorContainer: Color(0xFFFECACA),
      surface: Color(0xFF13201B),
      onSurface: Color(0xFFF1F5F9),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF233830),
      outlineVariant: Color(0xFF1D2F28),
      surfaceContainerHighest: Color(0xFF192A23),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBg: const Color(0xFF0B1310),
      ext: CalSnapColors.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffoldBg,
    required CalSnapColors ext,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      extensions: <ThemeExtension<dynamic>>[ext],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ext.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ext.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: ext.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.mutedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: ext.border),
      ),
    );
  }
}
