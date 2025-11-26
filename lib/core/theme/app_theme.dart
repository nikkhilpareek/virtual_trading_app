import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Premium Light Theme for Trading App
/// Royal Blue (#0061FF) primary with clean, professional aesthetics
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD6E4FF),
        onPrimaryContainer: Color(0xFF001C3A),

        secondary: AppColors.lightSecondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFB9F6CA),
        onSecondaryContainer: Color(0xFF00210B),

        tertiary: Color(0xFF6750A4),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFEADDFF),
        onTertiaryContainer: Color(0xFF21005E),

        error: AppColors.lightError,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),

        background: AppColors.lightBackground,
        onBackground: AppColors.lightTextPrimary,

        surface: AppColors.lightCardBackground,
        onSurface: AppColors.lightTextPrimary,
        surfaceVariant: Color(0xFFE1E2EC),
        onSurfaceVariant: AppColors.lightTextSecondary,

        outline: Color(0xFFCAC4D0),
        outlineVariant: Color(0xFFE7E0EC),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFF313033),
        onInverseSurface: Color(0xFFF4EFF4),
        inversePrimary: Color(0xFFAAC7FF),
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.lightBackground,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCardBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black12,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.lightPrimary, size: 24),
        actionsIconTheme: IconThemeData(
          color: AppColors.lightPrimary,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.lightCardBackground,
        elevation: 2,
        shadowColor: Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.lightPrimary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E2EC), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E2EC), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightError, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.lightTextSecondary.withOpacity(0.6),
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.lightError,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCardBackground,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE1E2EC),
        thickness: 1,
        space: 1,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.lightPrimary;
          }
          return const Color(0xFFE1E2EC);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.lightPrimary.withOpacity(0.5);
          }
          return const Color(0xFFE1E2EC);
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE1E2EC),
        deleteIconColor: AppColors.lightTextSecondary,
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lightPrimary,
        circularTrackColor: Color(0xFFE1E2EC),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.lightPrimary,
        inactiveTrackColor: const Color(0xFFE1E2EC),
        thumbColor: AppColors.lightPrimary,
        overlayColor: AppColors.lightPrimary.withOpacity(0.12),
        valueIndicatorColor: AppColors.lightPrimary,
      ),

      // Text Theme
      textTheme:
          const TextTheme(
            displayLarge: AppTextStyles.displayLarge,
            displayMedium: AppTextStyles.displayMedium,
            displaySmall: AppTextStyles.displaySmall,
            headlineLarge: AppTextStyles.headlineLarge,
            headlineMedium: AppTextStyles.headlineMedium,
            headlineSmall: AppTextStyles.headlineSmall,
            titleLarge: AppTextStyles.titleLarge,
            titleMedium: AppTextStyles.titleMedium,
            titleSmall: AppTextStyles.titleSmall,
            bodyLarge: AppTextStyles.bodyLarge,
            bodyMedium: AppTextStyles.bodyMedium,
            bodySmall: AppTextStyles.bodySmall,
            labelLarge: AppTextStyles.labelLarge,
            labelMedium: AppTextStyles.labelMedium,
            labelSmall: AppTextStyles.labelSmall,
          ).apply(
            bodyColor: AppColors.lightTextPrimary,
            displayColor: AppColors.lightTextPrimary,
          ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: Color(0xFF001C3A),
        primaryContainer: Color(0xFF003D82),
        onPrimaryContainer: Color(0xFFD6E4FF),

        secondary: AppColors.darkSecondary,
        onSecondary: Color(0xFF00210B),
        secondaryContainer: Color(0xFF005227),
        onSecondaryContainer: Color(0xFFB9F6CA),

        tertiary: Color(0xFFD0BCFF),
        onTertiary: Color(0xFF381E72),
        tertiaryContainer: Color(0xFF4F378B),
        onTertiaryContainer: Color(0xFFEADDFF),

        error: AppColors.darkError,
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),

        background: AppColors.darkBackground,
        onBackground: AppColors.darkTextPrimary,

        surface: AppColors.darkCardBackground,
        onSurface: AppColors.darkTextPrimary,
        surfaceVariant: Color(0xFF44464F),
        onSurfaceVariant: AppColors.darkTextSecondary,

        outline: Color(0xFF938F99),
        outlineVariant: Color(0xFF44464F),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFFE6E1E5),
        onInverseSurface: Color(0xFF313033),
        inversePrimary: Color(0xFF0061FF),
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackground,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCardBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black38,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.darkPrimary, size: 24),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.darkCardBackground,
        elevation: 4,
        shadowColor: Color(0x4D000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Color(0xFF001C3A),
          elevation: 4,
          shadowColor: AppColors.darkPrimary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Color(0xFF001C3A),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2128),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF44464F), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF44464F), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkError, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary.withOpacity(0.6),
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.darkError,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCardBackground,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: const Color(0xFF001C3A),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF44464F),
        thickness: 1,
        space: 1,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.darkPrimary;
          }
          return const Color(0xFF44464F);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.darkPrimary.withOpacity(0.5);
          }
          return const Color(0xFF44464F);
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF44464F),
        deleteIconColor: AppColors.darkTextSecondary,
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkPrimary,
        circularTrackColor: Color(0xFF44464F),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.darkPrimary,
        inactiveTrackColor: const Color(0xFF44464F),
        thumbColor: AppColors.darkPrimary,
        overlayColor: AppColors.darkPrimary.withOpacity(0.12),
        valueIndicatorColor: AppColors.darkPrimary,
      ),

      // Text Theme
      textTheme:
          const TextTheme(
            displayLarge: AppTextStyles.displayLarge,
            displayMedium: AppTextStyles.displayMedium,
            displaySmall: AppTextStyles.displaySmall,
            headlineLarge: AppTextStyles.headlineLarge,
            headlineMedium: AppTextStyles.headlineMedium,
            headlineSmall: AppTextStyles.headlineSmall,
            titleLarge: AppTextStyles.titleLarge,
            titleMedium: AppTextStyles.titleMedium,
            titleSmall: AppTextStyles.titleSmall,
            bodyLarge: AppTextStyles.bodyLarge,
            bodyMedium: AppTextStyles.bodyMedium,
            bodySmall: AppTextStyles.bodySmall,
            labelLarge: AppTextStyles.labelLarge,
            labelMedium: AppTextStyles.labelMedium,
            labelSmall: AppTextStyles.labelSmall,
          ).apply(
            bodyColor: AppColors.darkTextPrimary,
            displayColor: AppColors.darkTextPrimary,
          ),
    );
  }
}
