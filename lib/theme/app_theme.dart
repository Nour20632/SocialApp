import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core colors based on the new logo
  static const Color primaryBlue = Color(0xFF0033A0); // Royal Blue from the logo
  static const Color secondaryBlue = Color(0xFF0047BB); // Slightly lighter blue
  static const Color lightBlue = Color(0xFF4169E1); // Accent blue
  static const Color veryLightBlue = Color(0xFFE6EEFF); // Very light blue for backgrounds
  static const Color logoWhite = Color(0xFFF5F5F5); // White from the logo

  // Supporting colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF757575);
  static const Color mediumGrey = Color(0xFF9E9E9E);

  // Text colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF424242);
  static const Color textLight = Color(0xFF616161);
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on blue

  // Text theme with Poppins for Latin characters
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textMedium,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textMedium,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMedium,
      ),
    );
  }

  // Arabic text theme using Tajawal
  static TextTheme _buildArabicTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textMedium,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textMedium,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMedium,
      ),
    );
  }

  // Main theme with blue accent colors
  static ThemeData seenTheme(BuildContext context, {bool isArabic = false}) {
    final ThemeData base = ThemeData.light();

    // Set system overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
        tertiary: lightBlue,
        background: white,
        surface: white,
        error: Colors.red,
        onPrimary: white,
        onSecondary: white,
        onBackground: Colors.black87,
        onSurface: Colors.black87,
      ),
      textTheme:
          isArabic
              ? _buildArabicTextTheme(base.textTheme)
              : _buildTextTheme(base.textTheme),
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        elevation: 1,
        backgroundColor: white,
        foregroundColor: textDark,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: darkGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: veryLightBlue,
        labelStyle: const TextStyle(
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: textMedium.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(color: grey, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: primaryBlue, size: 24),
      primaryIconTheme: const IconThemeData(color: primaryBlue, size: 24),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryBlue,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: lightBlue.withOpacity(0.3),
      highlightColor: lightBlue.withOpacity(0.1),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryBlue;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: darkGrey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryBlue;
          }
          return darkGrey;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryBlue;
          }
          return grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryBlue.withOpacity(0.5);
          }
          return darkGrey.withOpacity(0.5);
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: darkGrey,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2,
            color: primaryBlue,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: veryLightBlue,
        disabledColor: grey,
        selectedColor: lightBlue,
        secondarySelectedColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: white,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Splash screen theme with blue brand color
  static ThemeData splashTheme(BuildContext context, {bool isArabic = false}) {
    final ThemeData base = ThemeData.dark();

    // Set system overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: primaryBlue,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: logoWhite,
        secondary: lightBlue,
        tertiary: secondaryBlue,
        background: primaryBlue,
        surface: primaryBlue,
        error: Colors.red,
        onPrimary: primaryBlue,
        onSecondary: primaryBlue,
        onBackground: logoWhite,
        onSurface: logoWhite,
        onError: white,
      ),
      textTheme:
          isArabic
              ? _buildArabicTextTheme(
                base.textTheme,
              ).apply(bodyColor: logoWhite, displayColor: logoWhite)
              : _buildTextTheme(
                base.textTheme,
              ).apply(bodyColor: logoWhite, displayColor: logoWhite),
      primaryColor: logoWhite,
      scaffoldBackgroundColor: primaryBlue,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: logoWhite,
        centerTitle: true,
        iconTheme: IconThemeData(color: logoWhite),
      ),
      iconTheme: const IconThemeData(color: logoWhite, size: 24),
    );
  }

  // Logo widget
  static Widget logoWidget(String logoAssetPath) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          logoAssetPath,
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}