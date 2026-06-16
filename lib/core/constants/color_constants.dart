import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Light Theme Colors ───
  static const Color primaryLight = Color(0xFF6C5CE7);
  static const Color primaryVariantLight = Color(0xFF5A4BD1);
  static const Color secondaryLight = Color(0xFF00CEC9);
  static const Color surfaceLight = Color(0xFFF8F9FE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF2D3436);
  static const Color textSecondaryLight = Color(0xFF636E72);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color errorLight = Color(0xFFE17055);

  // ─── Dark Theme Colors ───
  static const Color primaryDark = Color(0xFFA29BFE);
  static const Color primaryVariantDark = Color(0xFF8B80F9);
  static const Color secondaryDark = Color(0xFF55EFC4);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color backgroundDark = Color(0xFF13131A);
  static const Color cardDark = Color(0xFF252537);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB2BEC3);
  static const Color dividerDark = Color(0xFF3D3D50);
  static const Color errorDark = Color(0xFFFF7675);

  // ─── Category Colors ───
  static const Color foodColor = Color(0xFFFF6B6B);
  static const Color shoppingColor = Color(0xFFFECA57);
  static const Color travelColor = Color(0xFF48DBFB);
  static const Color utilitiesColor = Color(0xFFFF9FF3);
  static const Color entertainmentColor = Color(0xFFF368E0);
  static const Color healthColor = Color(0xFF26DE81);
  static const Color educationColor = Color(0xFF4ECDC4);
  static const Color subscriptionColor = Color(0xFFFF6348);
  static const Color othersColor = Color(0xFF576574);

  // ─── Gradient Colors ───
  static const List<Color> primaryGradient = [
    Color(0xFF6C5CE7),
    Color(0xFFA29BFE),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF00CEC9),
    Color(0xFF55EFC4),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFE17055),
    Color(0xFFFAB1A0),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFFA502),
    Color(0xFFFFD93D),
  ];

  static const List<Color> successGradient = [
    Color(0xFF26DE81),
    Color(0xFF20BF6B),
  ];

  static const List<Color> healthGradient = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
  ];

  static const List<Color> coachGradient = [
    Color(0xFFE66767),
    Color(0xFFF39C12),
  ];

  // ─── Health Score Colors ───
  static Color getHealthColor(double score) {
    if (score >= 80) return const Color(0xFF26DE81);
    if (score >= 60) return const Color(0xFF4ECDC4);
    if (score >= 40) return const Color(0xFFFFA502);
    if (score >= 20) return const Color(0xFFE17055);
    return const Color(0xFFFF6B6B);
  }

  static String getHealthLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Needs Work';
    return 'Critical';
  }

  // ─── Payment Method ───
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
        return Icons.flight_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
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
