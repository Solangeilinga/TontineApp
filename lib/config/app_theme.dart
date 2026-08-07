// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Palette principale — vert tontine africaine
  static const primary = Color(0xFF1B6B3A);       // Vert profond
  static const primaryLight = Color(0xFF2E8B57);   // Vert clair
  static const primarySurface = Color(0xFFE8F5EE); // Fond vert très clair
  static const accent = Color(0xFFE8A838);          // Or/Ambre africain
  static const accentLight = Color(0xFFFFF3DC);     // Fond doré clair

  // Neutres
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF2F4F6);
  static const border = Color(0xFFE0E4EA);

  // Textes
  static const textPrimary = Color(0xFF1A1D23);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFADB5BD);

  // États
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Statuts cotisation
  static const statusPending = Color(0xFFF59E0B);
  static const statusReceived = Color(0xFF22C55E);
  static const statusLate = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          // `background` est déprécié depuis Flutter 3.18 (fusionné dans
          // `surface`) — supprimé. `surface` ci-dessous porte déjà
          // explicitement la bonne couleur (AppColors.surface), donc rien
          // ne change visuellement. Rien dans le code ne lisait
          // `colorScheme.background` (vérifié), seulement `AppColors.background`
          // directement (une constante différente, toujours utilisée ailleurs).
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        // Boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),

        // BottomNav
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
          ),
        ),
      );
}

// Extensions de style texte
class AppTextStyles {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const h4 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
