import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Light Theme Colors (Clean & Modern Slate) ───
  static const Color primaryLight = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryVariantLight = Color(0xFF4338CA); // Indigo 700
  static const Color secondaryLight = Color(0xFF0EA5E9); // Sky 500
  static const Color surfaceLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color dividerLight = Color(0xFFF1F5F9); // Slate 100
  static const Color errorLight = Color(0xFFEF4444); // Red 500

  // ─── Dark Theme Colors (Deep & Premium Obsidian) ───
  static const Color primaryDark = Color(0xFF818CF8); // Indigo 400
  static const Color primaryVariantDark = Color(0xFF6366F1); // Indigo 500
  static const Color secondaryDark = Color(0xFF38BDF8); // Sky 400
  static const Color surfaceDark = Color(0xFF0B0F19); // Deep Blue-Black 950
  static const Color backgroundDark = Color(0xFF030712); // Pure Obsidian 950
  static const Color cardDark = Color(0xFF111827); // Zinc/Slate 900
  static const Color textPrimaryDark = Color(0xFFF9FAFB); // Gray 50
  static const Color textSecondaryDark = Color(0xFF9CA3AF); // Gray 400
  static const Color dividerDark = Color(0xFF1F2937); // Slate 800
  static const Color errorDark = Color(0xFFF87171); // Red 400

  // ─── Category Colors (Harmonious & Softer Shades) ───
  static const Color foodColor = Color(0xFFF87171); // Soft Coral Red
  static const Color shoppingColor = Color(0xFFFB923C); // Soft Peach Orange
  static const Color travelColor = Color(0xFF60A5FA); // Soft Sky Blue
  static const Color utilitiesColor = Color(0xFF2DD4BF); // Soft Mint Teal
  static const Color entertainmentColor = Color(0xFFC084FC); // Soft Lilac Purple
  static const Color healthColor = Color(0xFF34D399); // Soft Emerald Green
  static const Color educationColor = Color(0xFF818CF8); // Soft Indigo Blue
  static const Color subscriptionColor = Color(0xFFF43F5E); // Soft Rose Pink
  static const Color othersColor = Color(0xFF94A3B8); // Soft Muted Slate

  // ─── Gradient Colors (Vibrant but Balanced Glows) ───
  static const List<Color> primaryGradient = [
    Color(0xFF4F46E5),
    Color(0xFF818CF8),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF0EA5E9),
    Color(0xFF34D399),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFF43F5E),
    Color(0xFFFB923C),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFD97706),
    Color(0xFFFBBF24),
  ];

  static const List<Color> successGradient = [
    Color(0xFF059669),
    Color(0xFF34D399),
  ];

  static const List<Color> healthGradient = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
  ];

  static const List<Color> coachGradient = [
    Color(0xFFE11D48),
    Color(0xFFFB923C),
  ];

  // ─── Health Score Helper ───
  static Color getHealthColor(double score) {
    if (score >= 80) return const Color(0xFF34D399);
    if (score >= 60) return const Color(0xFF2DD4BF);
    if (score >= 40) return const Color(0xFFFB923C);
    if (score >= 20) return const Color(0xFFF87171);
    return const Color(0xFFF43F5E);
  }

  static String getHealthLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Needs Work';
    return 'Critical';
  }

  // ─── Payment Method Helper ───
  static IconData getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'upi':
        return Icons.phone_android_rounded;
      case 'card':
      case 'credit card':
      case 'debit card':
        return Icons.credit_card_rounded;
      case 'online':
      case 'net banking':
        return Icons.language_rounded;
      case 'cash':
      default:
        return Icons.money_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return foodColor;
      case 'shopping':
        return shoppingColor;
      case 'travel':
        return travelColor;
      case 'utilities':
        return utilitiesColor;
      case 'entertainment':
        return entertainmentColor;
      case 'health':
        return healthColor;
      case 'education':
        return educationColor;
      case 'subscription':
        return subscriptionColor;
      default:
        return othersColor;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'entertainment':
        return Icons.local_play_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'subscription':
        return Icons.subscriptions_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }
}
