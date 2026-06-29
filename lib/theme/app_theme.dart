import 'package:flutter/material.dart';

/// Brand + semantic colors, ported from the React app's CSS custom properties.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4A42D6);

  // Semantic
  static const Color income = Color(0xFF00C896);
  static const Color expense = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB347);
  static const Color danger = Color(0xFFFF4757);

  // Gradient end used by .card-gradient
  static const Color gradientEnd = Color(0xFF9C63FF);
}

/// Resolves theme-dependent surface colors (light vs dark), matching the
/// `:root` and `[data-theme="dark"]` blocks from global.css.
class AppPalette {
  final Color bg;
  final Color bgCard;
  final Color bgInput;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppPalette({
    required this.bg,
    required this.bgCard,
    required this.bgInput,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static const AppPalette light = AppPalette(
    bg: Color(0xFFF4F5FF),
    bgCard: Color(0xFFFFFFFF),
    bgInput: Color(0xFFF0F1FF),
    border: Color(0xFFE8E9FF),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
  );

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0F0E1A),
    bgCard: Color(0xFF1A1928),
    bgInput: Color(0xFF252438),
    border: Color(0xFF2D2B45),
    textPrimary: Color(0xFFF0F0FF),
    textSecondary: Color(0xFFA0A0C0),
    textMuted: Color(0xFF6B6B8A),
  );
}

/// Exposes the active [AppPalette] through the widget tree so individual
/// widgets can read theme-aware surface colors (Flutter's ThemeData does not
/// carry every custom token we need).
class AppPaletteScope extends InheritedWidget {
  final AppPalette palette;

  const AppPaletteScope({super.key, required this.palette, required super.child});

  static AppPalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppPaletteScope>();
    assert(scope != null, 'AppPaletteScope not found in widget tree');
    return scope!.palette;
  }

  @override
  bool updateShouldNotify(AppPaletteScope oldWidget) => palette != oldWidget.palette;
}

class AppTheme {
  const AppTheme._();

  static ThemeData _base(AppPalette p, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      surface: p.bgCard,
      error: AppColors.expense,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bg,
      textTheme: (brightness == Brightness.dark
              ? Typography.material2021().white
              : Typography.material2021().black)
          .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: p.textMuted),
        labelStyle: TextStyle(color: p.textSecondary),
      ),
    );
  }

  static ThemeData light() => _base(AppPalette.light, Brightness.light);
  static ThemeData dark() => _base(AppPalette.dark, Brightness.dark);
}
