import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette Fajafric — thème clair blanc/teal (identique au site React)
class AppTheme {
  // ── Couleurs principales (identiques au site React) ───────────
  static const Color primary      = Color(0xFF1A5F7A); // teal foncé site
  static const Color primaryDark  = Color(0xFF124557); // teal très foncé
  static const Color primaryLight = Color(0xFF7ECBEA); // bleu clair
  static const Color tealMid      = Color(0xFF2A8BAE); // teal moyen
  static const Color gold         = Color(0xFFC9920A);
  static const Color goldLight    = Color(0xFFE8C068);

  // ── Fonds clairs (blanc/bleu très léger — comme #f0f8fb du site) ──
  static const Color bg           = Color(0xFFF0F8FB); // fond principal
  static const Color bgCard       = Color(0xFFFFFFFF); // cartes blanches
  static const Color bgElevated   = Color(0xFFEAF4F9); // inputs, sections
  static const Color bgOverlay    = Color(0xFFD8EEF8); // chips, hover

  // ── Textes sombres sur fond clair ─────────────────────────────
  static const Color textPrimary   = Color(0xFF0E2A3A); // texte principal
  static const Color textSecondary = Color(0xFF4A7A92); // texte secondaire
  static const Color textMuted     = Color(0xFF8AABB8); // texte atténué

  // ── Bordures claires ──────────────────────────────────────────
  static const Color border       = Color(0xFFC8E4EF);
  static const Color borderLight  = Color(0xFFDFEFF7);

  // ── Sémantique ────────────────────────────────────────────────
  static const Color red          = Color(0xFFDC2626);
  static const Color green        = Color(0xFF0F766E);
  static const Color amber        = Color(0xFFD97706);
  static const Color white        = Color(0xFFFFFFFF);

  // ── Aliases rétrocompat ───────────────────────────────────────
  static const Color teal     = primary;
  static const Color tealDark = primaryDark;
  static const Color navy     = Color(0xFF0E1F33);
  static const Color ink      = textPrimary;
  static const Color inkSoft  = textSecondary;
  static const Color line     = border;

  // ── Thème principal (CLAIR) ───────────────────────────────────
  static ThemeData get theme {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary:    primary,
        secondary:  tealMid,
        surface:    bgCard,
        onPrimary:  white,
        onSurface:  textPrimary,
        outline:    border,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',

      // ── AppBar (teal) ────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: white, fontSize: 17, fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: white),
      ),

      // ── Bottom Nav (blanche) ─────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        indicatorColor: primary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 11);
          }
          return const TextStyle(color: textMuted, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: white, size: 22);
          }
          return const IconThemeData(color: textMuted, size: 22);
        }),
        elevation: 8,
        shadowColor: Color(0x1A1A5F7A),
      ),

      // ── Boutons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          shadowColor: primary,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      // ── Inputs ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: red),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),

      // ── Cartes ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: const DividerThemeData(color: border, thickness: 1),

      // ── Chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: bgElevated,
        selectedColor: primary,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
