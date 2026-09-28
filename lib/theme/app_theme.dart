import 'package:flutter/material.dart';

class AppTheme {
  // =========================
  // COLORES DE HUELLA
  // =========================

  static const Color verdePrincipal = Color(0xFF16A085);
  static const Color verdeOscuro = Color(0xFF126B5B);
  static const Color verdeClaro = Color(0xFFE8F5F1);

  static const Color fondo = Color(0xFFF4F7F5);

  static const Color textoPrincipal = Color(0xFF1F2933);
  static const Color textoSecundario = Color(0xFF6B7280);

  static const Color error = Color(0xFFD9534F);

  // =========================
  // TEMA GENERAL
  // =========================

  static ThemeData tema = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: fondo,

    colorScheme: ColorScheme.fromSeed(
      seedColor: verdePrincipal,
    ),

    // =========================
    // APP BAR
    // =========================

    appBarTheme: const AppBarTheme(
      backgroundColor: verdePrincipal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),

    // =========================
    // TEXTOS
    // =========================

    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textoPrincipal,
      ),

      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textoPrincipal,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        color: textoPrincipal,
      ),

      bodyMedium: TextStyle(
        fontSize: 15,
        color: textoSecundario,
      ),
    ),

    // =========================
    // CAMPOS DE TEXTO
    // =========================

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: verdePrincipal,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: error,
          width: 1.5,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: error,
          width: 2,
        ),
      ),

      labelStyle: const TextStyle(
        color: textoSecundario,
      ),

      prefixIconColor: verdePrincipal,
    ),

    // =========================
    // BOTONES PRINCIPALES
    // =========================

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: verdePrincipal,
        foregroundColor: Colors.white,

        minimumSize: const Size(
          double.infinity,
          52,
        ),

        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 20,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        elevation: 0,

        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // =========================
    // BOTONES SECUNDARIOS
    // =========================

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: verdePrincipal,

        minimumSize: const Size(
          double.infinity,
          52,
        ),

        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 20,
        ),

        side: const BorderSide(
          color: verdePrincipal,
          width: 1.5,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // =========================
    // TARJETAS
    // =========================

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,

      margin: const EdgeInsets.symmetric(
        vertical: 6,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    // =========================
    // ICONOS
    // =========================

    iconTheme: const IconThemeData(
      color: verdePrincipal,
    ),
  );
}