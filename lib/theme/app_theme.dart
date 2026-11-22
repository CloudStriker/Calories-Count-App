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
    required this.aiStart,
    required this.aiMid,
    required this.aiEnd,
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
  final Color aiStart;
  final Color aiMid;
  final Color aiEnd;

  static const CalSnapColors light = CalSnapColors(
    border: Color(0xFFE2E2E7),
    mutedSurface: Color(0xFFECECF0),
    mutedText: Color(0xFF5F5F67),
    proteinColor: Color(0xFF1D4ED8),
    carbsColor: Color(0xFF9A4D06),
    fatColor: Color(0xFFBE123C),
    successBg: Color(0xFFE7F8ED),
    successFg: Color(0xFF15803D),
    warningBg: Color(0xFFFFF4E0),
    warningFg: Color(0xFF9A4D06),
    errorBg: Color(0xFFFDECEF),
    errorFg: Color(0xFFB91C1C),
    aiStart: Color(0xFF2563EB),
    aiMid: Color(0xFF7C3AED),
    aiEnd: Color(0xFFE11D48),
  );

  static const CalSnapColors dark = CalSnapColors(
    border: Color(0xFF262626),
    mutedSurface: Color(0xFF1F1F1F),
    mutedText: Color(0xFF9A9AA0),
    proteinColor: Color(0xFF4DA8FF),
    carbsColor: Color(0xFFFFB54C),
    fatColor: Color(0xFFFF6E87),
    successBg: Color(0xFF11291B),
    successFg: Color(0xFF42E17D),
    warningBg: Color(0xFF2C2010),
    warningFg: Color(0xFFFFB54C),
    errorBg: Color(0xFF33161B),
    errorFg: Color(0xFFFF8599),
    aiStart: Color(0xFF4DA8FF),
    aiMid: Color(0xFF8B8DF5),
    aiEnd: Color(0xFFFF6E87),
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
    Color? aiStart,
    Color? aiMid,
    Color? aiEnd,
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
      aiStart: aiStart ?? this.aiStart,
      aiMid: aiMid ?? this.aiMid,
      aiEnd: aiEnd ?? this.aiEnd,
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
      aiStart: Color.lerp(aiStart, other.aiStart, t) ?? aiStart,
      aiMid: Color.lerp(aiMid, other.aiMid, t) ?? aiMid,
      aiEnd: Color.lerp(aiEnd, other.aiEnd, t) ?? aiEnd,
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
      primary: Color(0xFF0A0A0A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE8E8ED),
      onPrimaryContainer: Color(0xFF111113),
      secondary: Color(0xFF3A3A40),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE8E8ED),
      onSecondaryContainer: Color(0xFF111113),
      tertiary: Color(0xFF15803D),
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFB91C1C),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFDECEF),
      onErrorContainer: Color(0xFF991B1B),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF111113),
      onSurfaceVariant: Color(0xFF5F5F67),
      outline: Color(0xFFE2E2E7),
      outlineVariant: Color(0xFFEBEBF0),
      surfaceContainerHighest: Color(0xFFECECF0),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBg: const Color(0xFFF5F5F7),
      ext: CalSnapColors.light,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF0A0A0A),
      primaryContainer: Color(0xFF232326),
      onPrimaryContainer: Color(0xFFF5F5F7),
      secondary: Color(0xFFD4D4D8),
      onSecondary: Color(0xFF0A0A0A),
      secondaryContainer: Color(0xFF232326),
      onSecondaryContainer: Color(0xFFF5F5F7),
      tertiary: Color(0xFF42E17D),
      onTertiary: Color(0xFF071A0E),
      error: Color(0xFFFF8599),
      onError: Color(0xFF2A0A10),
      errorContainer: Color(0xFF33161B),
      onErrorContainer: Color(0xFFFFB4C0),
      surface: Color(0xFF151515),
      onSurface: Color(0xFFF5F5F7),
      onSurfaceVariant: Color(0xFF9A9AA0),
      outline: Color(0xFF262626),
      outlineVariant: Color(0xFF1E1E21),
      surfaceContainerHighest: Color(0xFF1F1F1F),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBg: const Color(0xFF0A0A0A),
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
    final isDark = scheme.brightness == Brightness.dark;

    final textTheme = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        height: 1.12,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.16,
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
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ext.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: ext.border),
          shape: const StadiumBorder(),
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
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.mutedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: ext.mutedSurface,
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: ext.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF262629) : const Color(0xFF18181B),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF5F5F7),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
