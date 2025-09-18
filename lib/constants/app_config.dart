// lib/constants/app_config.dart

class AppConfig {
  /// Base URL for the secure backend that proxies WooCommerce requests.
  ///
  /// The backend is responsible for handling authentication with WooCommerce
  /// so that sensitive credentials never ship with the application binary.
  static const String backendBaseUrl =
      "https://creditphoneqatar.com/wp-json/app-proxy/v1";

  /// Helper for building a backend [Uri] with optional query parameters while
  /// skipping null values.
  static Uri buildBackendUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$backendBaseUrl$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final sanitized = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value == null) return;
      sanitized[key] = value.toString();
    });

    if (sanitized.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: sanitized);
  }

  static const String jwtLoginUrl =
      "https://creditphoneqatar.com/wp-json/jwt-auth/v1/token";
}
