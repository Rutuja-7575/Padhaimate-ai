import 'package:flutter/material.dart';

class AppColors {
  static const bgDark = Color(0xFF0A0D17);
  static const panelDark = Color(0xFF10121F);
  static const cardDark = Color(0xFF171B2E);
  static const border = Color(0xFF2A2F45);
  static const lime = Color(0xFFD6FF3F);
  static const purple = Color(0xFF8C7EF0);
  static const textPrimary = Color(0xFFF5F5F7);
  static const textMuted = Color(0xFF8A8FA3);
  static const onlineGreen = Color(0xFF3DDC84);
}

class AppTheme {
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lime,
        secondary: AppColors.purple,
        surface: AppColors.cardDark,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.panelDark,
        indicatorColor: AppColors.lime.withOpacity(0.25),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.lime);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
        ),
      ),
    );
  }
}

class AppGradients {
  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF171B2E), Color(0xFF0A0D17)],
  );

  static const limeGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lime, Color(0xFFB8E82F)],
  );

  static const purpleGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purple, Color(0xFF6E5FE0)],
  );
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(color: color.withOpacity(0.35), blurRadius: 20, spreadRadius: 1),
      ];
}

