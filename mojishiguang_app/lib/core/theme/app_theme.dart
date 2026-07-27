import 'package:flutter/material.dart';

/// 墨迹时光应用主题配置
/// 主色：朱红色系（古代印章色）#C04040
/// 辅色：宣纸米黄色 #F5E6C8
/// 强调色：墨黑色 #1A1A1A
class AppTheme {
  AppTheme._();

  // ─── 色彩定义 ───────────────────────────────────────────────

  /// 朱红色 - 主色 (古代印章色)
  static const Color vermilion = Color(0xFFC04040);

  /// 朱红色浅色
  static const Color vermilionLight = Color(0xFFD97070);

  /// 朱红色深色
  static const Color vermilionDark = Color(0xFF8B2E2E);

  /// 宣纸米黄色 - 辅色
  static const Color paperYellow = Color(0xFFF5E6C8);

  /// 宣纸色浅色
  static const Color paperYellowLight = Color(0xFFFAF3E0);

  /// 宣纸色深色
  static const Color paperYellowDark = Color(0xFFE8D5A8);

  /// 墨黑色 - 强调色
  static const Color inkBlack = Color(0xFF1A1A1A);

  /// 墨黑色浅色
  static const Color inkBlackLight = Color(0xFF333333);

  // ─── 浅色主题 ───────────────────────────────────────────────

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: vermilion,
      onPrimary: Colors.white,
      primaryContainer: vermilionLight,
      onPrimaryContainer: Colors.white,
      secondary: paperYellow,
      onSecondary: inkBlack,
      secondaryContainer: paperYellowLight,
      onSecondaryContainer: inkBlackLight,
      tertiary: inkBlack,
      onTertiary: Colors.white,
      surface: paperYellowLight,
      onSurface: inkBlack,
      surfaceContainerHighest: paperYellow,
      onSurfaceVariant: inkBlackLight,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: const Color(0xFF9B8F80),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paperYellowLight,

      // ── 文字主题（思源宋体） ──
      textTheme: _buildTextTheme(),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: inkBlack,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: inkBlack.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── BottomNavigationBar ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: vermilion,
        unselectedItemColor: inkBlackLight.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 12,
        ),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: vermilion,
        unselectedLabelColor: inkBlackLight.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 14,
        ),
        indicatorColor: vermilion,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vermilion,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SourceHanSerifSC',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: vermilion,
          side: const BorderSide(color: vermilion, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SourceHanSerifSC',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── InputDecoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inkBlackLight.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inkBlackLight.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: vermilion, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          color: inkBlackLight,
        ),
        hintStyle: TextStyle(
          fontFamily: 'SourceHanSerifSC',
          color: inkBlackLight.withOpacity(0.5),
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: paperYellow,
        selectedColor: vermilion,
        labelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: inkBlack,
        ),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: inkBlackLight.withOpacity(0.12),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ─── 暗色主题 ───────────────────────────────────────────────

  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: vermilionLight,
      onPrimary: Colors.white,
      primaryContainer: vermilionDark,
      onPrimaryContainer: Colors.white,
      secondary: paperYellowDark,
      onSecondary: inkBlack,
      secondaryContainer: const Color(0xFF4A3F30),
      onSecondaryContainer: paperYellowLight,
      tertiary: Colors.white,
      onTertiary: inkBlack,
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFE0E0E0),
      surfaceContainerHighest: const Color(0xFF2C2C2C),
      onSurfaceVariant: const Color(0xFFC0C0C0),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      outline: const Color(0xFF8C7E6E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2C2C2C),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedItemColor: vermilionLight,
        unselectedItemColor: const Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 12,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: vermilionLight,
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 14,
        ),
        indicatorColor: vermilionLight,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vermilionLight,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SourceHanSerifSC',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: vermilionLight,
          side: BorderSide(color: vermilionLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'SourceHanSerifSC',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A3A3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: const Color(0xFF9E9E9E).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: const Color(0xFF9E9E9E).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: vermilionLight, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          color: Color(0xFFC0C0C0),
        ),
        hintStyle: TextStyle(
          fontFamily: 'SourceHanSerifSC',
          color: const Color(0xFF9E9E9E).withOpacity(0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF3A3A3A),
        selectedColor: vermilionDark,
        labelStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 13,
          color: Color(0xFFE0E0E0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'SourceHanSerifSC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF9E9E9E).withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ─── 文字主题构建 ───────────────────────────────────────────

  static TextTheme _buildTextTheme() {
    const String fontFamily = 'SourceHanSerifSC';
    return const TextTheme(
      displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2),
      displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0),
      displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8),
      headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6),
      headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4),
      headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2),
      titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1),
      titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1),
      titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1),
      bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5),
      bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25),
      bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4),
      labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1),
      labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5),
      labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5),
    );
  }
}
