// lib/core/utils/network_interceptor.dart
import 'dart:html' as html;

class NetworkInterceptor {
  static void initialize() {
    // Override window.fetch to handle CORS errors
    html.window.addEventListener('error', (event) {
      final error = event as html.ErrorEvent;
      if (error.message?.contains('CORS') == true || 
          error.message?.contains('ipapi') == true) {
        event.preventDefault();
        print('CORS error intercepted: \');
      }
    });
    
    // Also override fetch directly
    final originalFetch = html.window.fetch;
    html.window.fetch = (resource, init) {
      final url = resource.toString();
      if (url.contains('ipapi.co')) {
        print('Blocked ipapi call: \');
        return html.Future.value(html.Response('{}', {'status': 200}));
      }
      return originalFetch.call(resource, init);
    };
  }
}
