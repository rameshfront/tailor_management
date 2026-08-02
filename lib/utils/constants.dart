import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Tailor Shop Manager';
  static const String dbName = 'tailor_shop.db';
  static const int dbVersion = 1;

  // Order statuses
  static const String statusPending = 'Pending';
  static const String statusCutting = 'Cutting';
  static const String statusStitching = 'Stitching';
  static const String statusReady = 'Ready';
  static const String statusDelivered = 'Delivered';

  static const List<String> orderStatuses = [
    statusPending,
    statusCutting,
    statusStitching,
    statusReady,
    statusDelivered,
  ];

  // Payment statuses
  static const String paymentPending = 'Pending';
  static const String paymentPartial = 'Partial';
  static const String paymentPaid = 'Paid';

  static const List<String> paymentStatuses = [
    paymentPending,
    paymentPartial,
    paymentPaid,
  ];

  // Payment methods
  static const String paymentCash = 'Cash';
  static const String paymentUPI = 'UPI';
  static const String paymentCard = 'Card';

  static const List<String> paymentMethods = [
    paymentCash,
    paymentUPI,
    paymentCard,
  ];

  // Common dress types
  static const List<String> dressTypes = [
    'Shirt',
    'Pant',
    'Salwar Kameez',
    'Saree Blouse',
    'Kurta',
    'Lehenga',
    'Churidar',
    'Coat',
    'Blazer',
    'Frock',
    'Gown',
    'Other',
  ];

  // Settings keys
  static const String keyShopName = 'shop_name';
  static const String keyOwnerName = 'owner_name';
  static const String keyPhone = 'phone';
  static const String keyAddress = 'address';
  static const String keyCurrency = 'currency';
  static const String keyThemeMode = 'theme_mode';

  // Default settings
  static const String defaultShopName = 'G Tailoring';
  static const String defaultCurrency = '₹';
}

/// Color palette for the app
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5C6BC0); // Indigo
  static const Color primaryDark = Color(0xFF3949AB);
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color accent = Color(0xFFFF7043); // Deep Orange
  static const Color success = Color(0xFF43A047); // Green
  static const Color warning = Color(0xFFFB8C00); // Orange
  static const Color error = Color(0xFFE53935); // Red
  static const Color info = Color(0xFF1E88E5); // Blue

  // Status colors
  static Color statusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return const Color(0xFFFB8C00);
      case AppConstants.statusCutting:
        return const Color(0xFF1E88E5);
      case AppConstants.statusStitching:
        return const Color(0xFF8E24AA);
      case AppConstants.statusReady:
        return const Color(0xFF43A047);
      case AppConstants.statusDelivered:
        return const Color(0xFF546E7A);
      default:
        return const Color(0xFF757575);
    }
  }

  // Payment status colors
  static Color paymentColor(String status) {
    switch (status) {
      case AppConstants.paymentPending:
        return const Color(0xFFE53935);
      case AppConstants.paymentPartial:
        return const Color(0xFFFB8C00);
      case AppConstants.paymentPaid:
        return const Color(0xFF43A047);
      default:
        return const Color(0xFF757575);
    }
  }
}
