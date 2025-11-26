import 'package:flutter/material.dart';

/// Premium Trading App Color Palette
/// Designed for financial/trading applications with strong visual hierarchy
class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(
    0xFF0061FF,
  ); // Royal Blue - Trust & Reliability
  static const Color lightSecondary = Color(
    0xFF00C853,
  ); // Green - Profit Indicator
  static const Color lightBackground = Color(
    0xFFF5F7FA,
  ); // Light Grey - Easy on eyes
  static const Color lightCardBackground = Color(
    0xFFFFFFFF,
  ); // Pure White Cards
  static const Color lightTextPrimary = Color(0xFF1C1C1C); // Almost Black
  static const Color lightTextSecondary = Color(0xFF5F6368); // Grey Text
  static const Color lightError = Color(0xFFD32F2F); // Red - Loss Indicator
  static const Color lightSuccess = Color(0xFF00C853); // Same as secondary
  static const Color lightWarning = Color(0xFFFF9800); // Amber
  static const Color lightInfo = Color(0xFF2196F3); // Light Blue

  // Dark Theme Colors (GitHub + Bloomberg Terminal inspired)
  static const Color darkPrimary = Color(
    0xFF4D8DFF,
  ); // Light Blue - Softer on eyes
  static const Color darkSecondary = Color(0xFF27C46D); // Light Green - Profit
  static const Color darkBackground = Color(0xFF0D1117); // GitHub Dark
  static const Color darkCardBackground = Color(0xFF161B22); // Elevated Dark
  static const Color darkTextPrimary = Color(0xFFE6E6E6); // Light Grey
  static const Color darkTextSecondary = Color(0xFF9BA3B0); // Muted Grey
  static const Color darkError = Color(0xFFFF6B6B); // Soft Red
  static const Color darkSuccess = Color(0xFF27C46D); // Same as secondary
  static const Color darkWarning = Color(0xFFFFB74D); // Soft Amber
  static const Color darkInfo = Color(0xFF64B5F6); // Soft Blue

  // Semantic Colors (context-independent)
  static const Color profit = Color(0xFF00C853);
  static const Color loss = Color(0xFFD32F2F);
  static const Color neutral = Color(0xFF9E9E9E);

  // Chart Colors
  static const Color chartGreen = Color(0xFF26A69A);
  static const Color chartRed = Color(0xFFEF5350);
  static const Color chartBlue = Color(0xFF42A5F5);
  static const Color chartOrange = Color(0xFFFF7043);
  static const Color chartPurple = Color(0xFFAB47BC);

  // Gradients
  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF64DD17)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lossGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0061FF), Color(0xFF4D8DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
