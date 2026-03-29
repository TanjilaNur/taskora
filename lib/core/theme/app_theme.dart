import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const _primary       = Color(0xFF6C63FF); // indigo-violet
  static const _primaryDark   = Color(0xFF8B83FF); // lighter for dark mode
  static const _secondary     = Color(0xFF00D4B4); // teal accent
  static const _tertiary      = Color(0xFFFF6B9D); // coral-pink accent
  static const _error         = Color(0xFFFF5252); // vivid red
  static const _successGreen  = Color(0xFF00C896); // emerald
  static const _warningOrange = Color(0xFFFF9F43); // warm orange

  // ── Semantic colours exposed for widgets ───────────────────────────────────
  static const successGreen  = _successGreen;
  static const warningOrange = _warningOrange;
  static const primaryColor  = _primary;

  // ── Light surface tokens ───────────────────────────────────────────────────
  static const _lightBg       = Color(0xFFF5F4FF); // very light lavender tint
  static const _lightSurface  = Color(0xFFFFFFFF);
  static const _lightSurface2 = Color(0xFFF0EFFE); // card tint

  // ── Dark surface tokens ────────────────────────────────────────────────────
  static const _darkBg        = Color(0xFF0F0E1A); // deep navy-black
  static const _darkSurface   = Color(0xFF1C1B2E); // card bg
  static const _darkSurface2  = Color(0xFF252438); // slightly lighter

  // ── Shared shape constants ─────────────────────────────────────────────────
  static const _radiusCard   = 18.0;
  static const _radiusInput  = 14.0;
  static const _radiusChip   = 24.0;
  static const _radiusSheet  = 28.0;
  static const _radiusFAB    = 20.0;

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary:            _primary,
      onPrimary:          Colors.white,
      primaryContainer:   const Color(0xFFE8E6FF),
      onPrimaryContainer: const Color(0xFF1A0066),
      secondary:          _secondary,
      onSecondary:        Colors.white,
      secondaryContainer: const Color(0xFFD0FFF5),
      onSecondaryContainer: const Color(0xFF00382E),
      tertiary:           _tertiary,
      onTertiary:         Colors.white,
      tertiaryContainer:  const Color(0xFFFFD9E8),
      onTertiaryContainer: const Color(0xFF3A0020),
      error:              _error,
      onError:            Colors.white,
      errorContainer:     const Color(0xFFFFDAD6),
      onErrorContainer:   const Color(0xFF410002),
      surface:            _lightSurface,
      onSurface:          const Color(0xFF1C1B2E),
      surfaceContainerHighest: _lightSurface2,
      onSurfaceVariant:   const Color(0xFF7B7A8F),
      outline:            const Color(0xFFCAC9D8),
      outlineVariant:     const Color(0xFFE5E4F0),
      shadow:             Colors.black,
      scrim:              Colors.black,
      inverseSurface:     const Color(0xFF1C1B2E),
      onInverseSurface:   Colors.white,
      inversePrimary:     _primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _lightBg,
      fontFamily: 'Roboto',

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _lightBg,
        foregroundColor: const Color(0xFF1C1B2E),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1C1B2E),
          letterSpacing: -0.5,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: _lightSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 10),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusFAB),
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: Color(0xFFCAC9D8),
        dragHandleSize: Size(40, 4),
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_radiusSheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface2,
        hintStyle: const TextStyle(color: Color(0xFFAEADC0), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: Color(0xFFE5E4F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurface2,
        selectedColor: _primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusChip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: false,
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Snackbar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1B2E),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E4F0),
        thickness: 1,
        space: 1,
      ),

      // ── Typography ─────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(const Color(0xFF1C1B2E)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary:            _primaryDark,
      onPrimary:          const Color(0xFF1A0066),
      primaryContainer:   const Color(0xFF3B3580),
      onPrimaryContainer: const Color(0xFFE8E6FF),
      secondary:          _secondary,
      onSecondary:        const Color(0xFF00382E),
      secondaryContainer: const Color(0xFF004D40),
      onSecondaryContainer: const Color(0xFFD0FFF5),
      tertiary:           _tertiary,
      onTertiary:         const Color(0xFF3A0020),
      tertiaryContainer:  const Color(0xFF5C0035),
      onTertiaryContainer: const Color(0xFFFFD9E8),
      error:              const Color(0xFFFF8A80),
      onError:            const Color(0xFF690005),
      errorContainer:     const Color(0xFF93000A),
      onErrorContainer:   const Color(0xFFFFDAD6),
      surface:            _darkSurface,
      onSurface:          const Color(0xFFE8E6FF),
      surfaceContainerHighest: _darkSurface2,
      onSurfaceVariant:   const Color(0xFFABA9C3),
      outline:            const Color(0xFF4A4868),
      outlineVariant:     const Color(0xFF35334E),
      shadow:             Colors.black,
      scrim:              Colors.black,
      inverseSurface:     const Color(0xFFE8E6FF),
      onInverseSurface:   const Color(0xFF1C1B2E),
      inversePrimary:     _primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _darkBg,
      fontFamily: 'Roboto',

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: const Color(0xFFE8E6FF),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE8E6FF),
          letterSpacing: -0.5,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkSurface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 10),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: const Color(0xFF1A0066),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusFAB),
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: Color(0xFF4A4868),
        dragHandleSize: Size(40, 4),
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_radiusSheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface2,
        hintStyle: const TextStyle(color: Color(0xFF6E6C85), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: Color(0xFF35334E), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusInput),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface2,
        selectedColor: _primaryDark,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusChip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: false,
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Snackbar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface2,
        contentTextStyle: const TextStyle(color: Color(0xFFE8E6FF), fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF35334E),
        thickness: 1,
        space: 1,
      ),

      // ── Typography ─────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(const Color(0xFFE8E6FF)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED TYPOGRAPHY
  // ─────────────────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color onSurface) {
    return TextTheme(
      displayLarge:  _ts(57, FontWeight.w400, onSurface, -0.25),
      displayMedium: _ts(45, FontWeight.w400, onSurface, 0),
      displaySmall:  _ts(36, FontWeight.w400, onSurface, 0),
      headlineLarge: _ts(32, FontWeight.w700, onSurface, -0.5),
      headlineMedium:_ts(28, FontWeight.w700, onSurface, -0.3),
      headlineSmall: _ts(24, FontWeight.w700, onSurface, -0.2),
      titleLarge:    _ts(22, FontWeight.w700, onSurface, -0.2),
      titleMedium:   _ts(16, FontWeight.w600, onSurface, 0.1),
      titleSmall:    _ts(14, FontWeight.w600, onSurface, 0.1),
      bodyLarge:     _ts(16, FontWeight.w400, onSurface, 0.5),
      bodyMedium:    _ts(14, FontWeight.w400, onSurface, 0.25),
      bodySmall:     _ts(12, FontWeight.w400, onSurface.withValues(alpha: 0.7), 0.4),
      labelLarge:    _ts(14, FontWeight.w600, onSurface, 0.1),
      labelMedium:   _ts(12, FontWeight.w600, onSurface, 0.5),
      labelSmall:    _ts(11, FontWeight.w500, onSurface.withValues(alpha: 0.7), 0.5),
    );
  }

  static TextStyle _ts(double size, FontWeight w, Color c, double spacing) =>
      TextStyle(
        fontFamily: 'Roboto',
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: spacing,
      );
}

