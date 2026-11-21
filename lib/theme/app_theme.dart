import 'package:material_ui/material_ui.dart';

const List<FontFeature> tabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

abstract final class CalSnapMotion {
  static const Curve easeOut = Cubic(0.23, 1.0, 0.32, 1.0);
  static const Duration pressDuration = Duration(milliseconds: 130);
  static const Duration transitionDuration = Duration(milliseconds: 220);
}

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
    border: Color(0xFFE6DDD1),
    mutedSurface: Color(0xFFF3ECE3),
    mutedText: Color(0xFF57534E),
    proteinColor: Color(0xFF9A3412),
    carbsColor: Color(0xFFB45309),
    fatColor: Color(0xFF4D7C0F),
    successBg: Color(0xFFECF3E6),
    successFg: Color(0xFF365314),
    warningBg: Color(0xFFFEF3C7),
    warningFg: Color(0xFF92400E),
    errorBg: Color(0xFFFEE2E2),
    errorFg: Color(0xFF991B1B),
  );

  static const CalSnapColors dark = CalSnapColors(
    border: Color(0xFF332C26),
    mutedSurface: Color(0xFF26211D),
    mutedText: Color(0xFFA8A096),
    proteinColor: Color(0xFFFB923C),
    carbsColor: Color(0xFFFBBF24),
    fatColor: Color(0xFFA8C66C),
    successBg: Color(0xFF1F2D18),
    successFg: Color(0xFFCBE0A8),
    warningBg: Color(0xFF38260E),
    warningFg: Color(0xFFFDE68A),
    errorBg: Color(0xFF3F1515),
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
      mutedSurface:
          Color.lerp(mutedSurface, other.mutedSurface, t) ?? mutedSurface,
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
      primary: Color(0xFF9A3412),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFDECE3),
      onPrimaryContainer: Color(0xFF7C2D12),
      secondary: Color(0xFFC2410C),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFEDD5),
      onSecondaryContainer: Color(0xFF7C2D12),
      tertiary: Color(0xFF4D7C0F),
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFB91C1C),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1C1917),
      onSurfaceVariant: Color(0xFF57534E),
      outline: Color(0xFFE6DDD1),
      outlineVariant: Color(0xFFEFE8DF),
      surfaceContainerHighest: Color(0xFFF3ECE3),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBg: const Color(0xFFFAF6F0),
      ext: CalSnapColors.light,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFB923C),
      onPrimary: Color(0xFF1F1108),
      primaryContainer: Color(0xFF3D1F0E),
      onPrimaryContainer: Color(0xFFFED7AA),
      secondary: Color(0xFFFDBA74),
      onSecondary: Color(0xFF1F1108),
      secondaryContainer: Color(0xFF3A2112),
      onSecondaryContainer: Color(0xFFFFEDD5),
      tertiary: Color(0xFFA8C66C),
      onTertiary: Color(0xFF18230A),
      error: Color(0xFFF87171),
      onError: Color(0xFF2A0A0A),
      errorContainer: Color(0xFF3F1515),
      onErrorContainer: Color(0xFFFECACA),
      surface: Color(0xFF1C1815),
      onSurface: Color(0xFFF5F1EC),
      onSurfaceVariant: Color(0xFFA8A096),
      outline: Color(0xFF332C26),
      outlineVariant: Color(0xFF2B2420),
      surfaceContainerHighest: Color(0xFF26211D),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBg: const Color(0xFF12100E),
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

    final textTheme = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.45,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
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
          borderRadius: BorderRadius.circular(18),
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
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: ext.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.mutedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ext.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ext.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: ext.border),
      ),
    );
  }
}
