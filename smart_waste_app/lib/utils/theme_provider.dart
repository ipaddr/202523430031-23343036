import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  late SharedPreferences _prefs;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs.setBool(_themeKey, isDark);
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B7A3E),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFBFE),
        surfaceVariant: const Color(0xFFF5F5F5),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      canvasColor: const Color(0xFFFFFFFF),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        iconTheme: IconThemeData(color: Color(0xFF1B7A3E)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1B7A3E),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B7A3E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF666666)),
        errorStyle: const TextStyle(color: Color(0xFFD32F2F)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B7A3E),
          foregroundColor: const Color(0xFFFFFFFF),
          disabledBackgroundColor: const Color(0xFFE0E0E0),
          disabledForegroundColor: const Color(0xFF999999),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1B7A3E),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1B7A3E),
          side: const BorderSide(color: Color(0xFF1B7A3E), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: const Color(0xFF1B7A3E)),
      ),

      // Chip Theme
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFFF0F0F0),
        disabledColor: Color(0xFFE0E0E0),
        selectedColor: Color(0xFF1B7A3E),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelStyle: TextStyle(color: Color(0xFF333333), fontSize: 13),
        secondaryLabelStyle: TextStyle(color: Color(0xFF666666), fontSize: 13),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1B7A3E),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFF1B7A3E), width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Color(0xFF1B7A3E),
        unselectedLabelColor: Color(0xFF999999),
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF1B7A3E),
        refreshBackgroundColor: Color(0xFFF0F0F0),
      ),

      // Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF1B7A3E),
        inactiveTrackColor: Color(0xFFE0E0E0),
        disabledActiveTrackColor: Color(0xFFBFBFBF),
        disabledInactiveTrackColor: Color(0xFFDFDFDF),
        activeTickMarkColor: Color(0xFF1B7A3E),
        inactiveTickMarkColor: Color(0xFFBFBFBF),
        disabledActiveTickMarkColor: Color(0xFFCCCCCC),
        disabledInactiveTickMarkColor: Color(0xFFE0E0E0),
        thumbColor: Color(0xFF1B7A3E),
        disabledThumbColor: Color(0xFFBFBFBF),
        overlayColor: Color(0x301B7A3E),
        valueIndicatorColor: Color(0xFF1B7A3E),
        valueIndicatorTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        trackHeight: 6,
        rangeThumbShape: RoundRangeSliderThumbShape(
          elevation: 4,
          enabledThumbRadius: 8,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 16,
      ),

      // Text Themes
      textTheme: const TextTheme(
        // Headlines
        displayLarge: TextStyle(
          color: Color(0xFF1B1B1B),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF1B1B1B),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Color(0xFF1B1B1B),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: Color(0xFF1B7A3E),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1B7A3E),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF1B7A3E),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        // Title
        titleLarge: TextStyle(
          color: Color(0xFF1B1B1B),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF666666),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        // Body
        bodyLarge: TextStyle(
          color: Color(0xFF1B1B1B),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF666666),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        // Label
        labelLarge: TextStyle(
          color: Color(0xFF1B7A3E),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: Color(0xFF666666),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF999999),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1B7A3E);
          }
          return const Color(0xFFE0E0E0);
        }),
        checkColor: MaterialStateProperty.all(const Color(0xFFFFFFFF)),
        side: const BorderSide(color: Color(0xFF1B7A3E), width: 2),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1B7A3E);
          }
          return const Color(0xFFE0E0E0);
        }),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1B7A3E);
          }
          return const Color(0xFFBFBFBF);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1B7A3E88);
          }
          return const Color(0xFFDFDFDF88);
        }),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1B7A3E),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 10,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 8,
        indicatorColor: const Color(0xFF1B7A3E),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1B7A3E),
          ),
        ),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFF1B1B1B),
        iconColor: Color(0xFF666666),
        selectedTileColor: Color(0xFFF0F0F0),
        selectedColor: Color(0xFF1B7A3E),
      ),

      // Snackbar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1B1B1B),
        contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xFF1B1B1B),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
        surfaceVariant: const Color(0xFF2C2C2C),
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF121212),
      canvasColor: const Color(0xFF1E1E1E),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        errorStyle: const TextStyle(color: Color(0xFFEF5350)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: const Color(0xFFFFFFFF),
          disabledBackgroundColor: const Color(0xFF404040),
          disabledForegroundColor: const Color(0xFF808080),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
          side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF)),
      ),

      // Chip Theme
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        disabledColor: Color(0xFF404040),
        selectedColor: Color(0xFF4CAF50),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelStyle: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
        secondaryLabelStyle: TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFF4CAF50), width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Color(0xFF4CAF50),
        unselectedLabelColor: Color(0xFF888888),
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF4CAF50),
        refreshBackgroundColor: Color(0xFF2C2C2C),
      ),

      // Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF4CAF50),
        inactiveTrackColor: Color(0xFF404040),
        disabledActiveTrackColor: Color(0xFF606060),
        disabledInactiveTrackColor: Color(0xFF303030),
        activeTickMarkColor: Color(0xFF4CAF50),
        inactiveTickMarkColor: Color(0xFF606060),
        disabledActiveTickMarkColor: Color(0xFF808080),
        disabledInactiveTickMarkColor: Color(0xFF404040),
        thumbColor: Color(0xFF4CAF50),
        disabledThumbColor: Color(0xFF606060),
        overlayColor: Color(0x304CAF50),
        valueIndicatorColor: Color(0xFF1B7A3E),
        valueIndicatorTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        trackHeight: 6,
        rangeThumbShape: RoundRangeSliderThumbShape(
          elevation: 4,
          enabledThumbRadius: 8,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
        space: 16,
      ),

      // Text Themes
      textTheme: const TextTheme(
        // Headlines
        displayLarge: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        // Title
        titleLarge: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        // Body
        bodyLarge: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF999999),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        // Label
        labelLarge: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF888888),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF4CAF50);
          }
          return const Color(0xFF404040);
        }),
        checkColor: MaterialStateProperty.all(const Color(0xFFFFFFFF)),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF4CAF50);
          }
          return const Color(0xFF404040);
        }),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF4CAF50);
          }
          return const Color(0xFF606060);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF4CAF5044);
          }
          return const Color(0xFF40404088);
        }),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 10,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 8,
        indicatorColor: const Color(0xFF4CAF50),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFFFFFFF),
        iconColor: Color(0xFFB0B0B0),
        selectedTileColor: Color(0xFF2C2C2C),
        selectedColor: Color(0xFF4CAF50),
      ),

      // Snackbar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Tooltip Theme
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xFF404040),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
      ),
    );
  }
}
