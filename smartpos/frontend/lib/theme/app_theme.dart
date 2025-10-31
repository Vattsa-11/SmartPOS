import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getThemeData() {
    // Define colors from the provided palette
    const primaryColor = Color(0xFF166088); // Deep blue
    const secondaryColor = Color(0xFF4A6FA5); // Medium blue
    const surfaceColor = Color(0xFF4F6D7A); // Slate blue-gray
    const backgroundColor = Color(0xFF293241); // Dark background
    const accentColor = Color(0xFFC0D6DF); // Light blue-gray
    const lightColor = Color(0xFFDBE9EE); // Very light blue-gray
    
    return ThemeData.dark().copyWith(
      // Primary and secondary colors
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: Colors.redAccent,
      ),
      
      // App Bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: lightColor,
        elevation: 2,
        centerTitle: true,
      ),
      
      // Elevated Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: lightColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text Button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      
      // Card theme
      cardColor: surfaceColor,
      
      // Text theme with larger fonts
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightColor),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightColor),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightColor),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: lightColor),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightColor),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: accentColor),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: accentColor),
        bodyLarge: TextStyle(fontSize: 18, color: accentColor), // Larger body text for readability
        bodyMedium: TextStyle(fontSize: 16, color: accentColor), // Larger body text for readability
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.all(16),
        labelStyle: const TextStyle(color: accentColor),
        hintStyle: TextStyle(color: accentColor.withOpacity(0.7)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: accentColor,
        size: 24,
      ),
      
      // Scaffold background color
      scaffoldBackgroundColor: backgroundColor,
      
      // Dialog background color
      dialogBackgroundColor: surfaceColor,
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        disabledColor: surfaceColor.withOpacity(0.6),
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        labelStyle: const TextStyle(color: lightColor),
        secondaryLabelStyle: const TextStyle(color: lightColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: accentColor, width: 1),
        ),
      ),
    );
  }
}
