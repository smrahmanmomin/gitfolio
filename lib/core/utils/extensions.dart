import 'package:flutter/material.dart';

/// Extension methods for common operations throughout the app.
///
/// This file contains utility extensions for String, DateTime, and BuildContext
/// to provide convenient methods for validation, formatting, and UI helpers.

// ==================== String Extensions ====================

/// Extensions on [String] for validation and formatting.
extension StringExtensions on String {
  /// Validates if the string is a valid email address.
  ///
  /// Returns `true` if the string matches a standard email format.
  ///
  /// Example:
  /// ```dart
  /// 'user@example.com'.isValidEmail; // true
  /// 'invalid-email'.isValidEmail; // false
  /// ```
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Capitalizes the first letter of the string.
  ///
  /// Returns the string with the first character in uppercase and the rest unchanged.
  ///
  /// Example:
  /// ```dart
  /// 'hello world'.capitalizeFirst; // 'Hello world'
  /// 'FLUTTER'.capitalizeFirst; // 'FLUTTER'
  /// ```
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of each word.
  ///
  /// Example:
  /// ```dart
  /// 'hello world'.capitalizeWords; // 'Hello World'
  /// ```
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalizeFirst).join(' ');
  }

  /// Validates if the string is a valid URL.
  ///
  /// Returns `true` if the string is a properly formatted URL with scheme and authority.
  bool get isValidUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Truncates the string to the specified length and adds ellipsis if needed.
  ///
  /// Example:
  /// ```dart
  /// 'This is a long text'.truncate(10); // 'This is a...'
  /// ```
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Removes all whitespace from the string.
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Validates if the string is a valid GitHub username.
  ///
  /// GitHub usernames can only contain alphanumeric characters and hyphens,
  /// cannot start or end with a hyphen, and must be 1-39 characters long.
  bool get isValidGitHubUsername {
    final usernameRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$',
    );
    return usernameRegex.hasMatch(this);
  }
}

// ==================== DateTime Extensions ====================

/// Extensions on [DateTime] for formatting and relative time display.
extension DateTimeExtensions on DateTime {
  /// Formats the date as a readable string (e.g., "Jan 15, 2024").
  ///
  /// Example:
  /// ```dart
  /// DateTime(2024, 1, 15).formattedDate; // 'Jan 15, 2024'
  /// ```
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[month - 1]} $day, $year';
  }

  /// Formats the date with time (e.g., "Jan 15, 2024 at 3:30 PM").
  String get formattedDateTime {
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$formattedDate at $hour12:$minuteStr $period';
  }

  /// Returns a human-readable "time ago" string (e.g., "2 hours ago", "3 days ago").
  ///
  /// Example:
  /// ```dart
  /// DateTime.now().subtract(Duration(hours: 2)).timeAgo; // '2 hours ago'
  /// DateTime.now().subtract(Duration(days: 3)).timeAgo; // '3 days ago'
  /// ```
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Checks if the date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if the date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns a short relative date string (e.g., "Today", "Yesterday", or formatted date).
  String get shortRelativeDate {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return formattedDate;
  }
}

// ==================== BuildContext Extensions ====================

/// Extensions on [BuildContext] for convenient access to common properties.
extension ContextExtensions on BuildContext {
  /// Returns the screen size from MediaQuery.
  ///
  /// Example:
  /// ```dart
  /// final size = context.screenSize;
  /// final width = size.width;
  /// ```
  Size get screenSize => MediaQuery.of(this).size;

  /// Returns the screen width.
  double get screenWidth => screenSize.width;

  /// Returns the screen height.
  double get screenHeight => screenSize.height;

  /// Checks if the current theme is in dark mode.
  ///
  /// Example:
  /// ```dart
  /// if (context.isDarkMode) {
  ///   // Use dark mode specific styling
  /// }
  /// ```
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Returns the current theme data.
  ThemeData get theme => Theme.of(this);

  /// Returns the current color scheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Returns the current text theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shows a snackbar with the given message.
  ///
  /// Example:
  /// ```dart
  /// context.showSnackBar('Operation completed successfully');
  /// ```
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
  }

  /// Shows an error snackbar with the given message.
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a success snackbar with the given message.
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Checks if the keyboard is visible.
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Returns the padding for safe areas (notches, status bar, etc.).
  EdgeInsets get padding => MediaQuery.of(this).padding;

  /// Returns the view insets (usually keyboard height).
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Hides the keyboard by removing focus from any text field.
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Checks if the device is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Checks if the device is in portrait orientation.
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Returns true if the screen width is considered small (phone).
  bool get isSmallScreen => screenWidth < 600;

  /// Returns true if the screen width is considered medium (tablet).
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  /// Returns true if the screen width is considered large (desktop).
  bool get isLargeScreen => screenWidth >= 1200;
}

// ==================== Number Extensions ====================

/// Extensions on [num] for formatting and utilities.
extension NumExtensions on num {
  /// Formats a number with K/M/B suffixes for large numbers.
  ///
  /// Example:
  /// ```dart
  /// 1234.formatCompact; // '1.2K'
  /// 1234567.formatCompact; // '1.2M'
  /// ```
  String get formatCompact {
    if (this >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(1)}B';
    } else if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }

  /// Formats a number with thousand separators.
  ///
  /// Example:
  /// ```dart
  /// 1234567.formatWithCommas; // '1,234,567'
  /// ```
  String get formatWithCommas {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
