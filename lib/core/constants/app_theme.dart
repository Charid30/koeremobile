import 'package:flutter/material.dart';

/// Couleurs et thème SOFARY, alignés sur le site web :
/// violet du logo (#351266) décliné en gamme, rouge réservé aux alertes.
class AppTheme {
  // Marque
  static const Color brand = Color(0xFF351266); // violet du logo
  static const Color brandRed = Color(0xFFF70205); // rouge du logo (accent rare)

  // Gamme violette (mêmes valeurs que --color-primary-* du site)
  static const Color primary = Color(0xFF7135D4); // 600 : boutons, liens
  static const Color primaryDark = Color(0xFF5C24B1); // 700 : appui
  static const Color primaryLight = Color(0xFFF6F3FF); // 50 : fonds teintés
  static const Color primaryBorder = Color(0xFFDCD1FF); // 200 : bordures teintées

  // États
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color success = Color(0xFF16A34A);

  // Neutres
  static const Color surface = Color(0xFFF9FAFB);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static final ColorScheme _scheme = ColorScheme.fromSeed(
    seedColor: brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: primaryLight,
    onPrimaryContainer: brand,
    secondary: brand,
    error: danger,
    surface: Colors.white,
    surfaceTint: Colors.transparent,
    outline: border,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: _scheme,
        scaffoldBackgroundColor: surface,
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border),
          ),
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primary.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: primaryLight,
          elevation: 0,
          height: 68,
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? primary : textSecondary),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? primary : textSecondary,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: primaryLight,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          labelStyle: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: textPrimary),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: brand,
          contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
