// Utility functions for the application
class AppUtils {
  // Format date to readable string
  static String formatDate(DateTime date) {
    return '{date.day}/{date.month}/{date.year}';
  }

  // Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
}
