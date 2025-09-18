// lib/constants/app_config.dart

import 'dart:convert';

class AppConfig {
  /// Base URL for the WooCommerce REST API.
  static const String backendBaseUrl =
      "https://creditphoneqatar.com/wp-json/wc/v3";

  /// Consumer key for authenticating against WooCommerce.
  ///
  /// Provide a value at build time using:
  /// `flutter run --dart-define=WOO_CONSUMER_KEY=ck_xxx`.
  static const String consumerKey =
      String.fromEnvironment('WOO_CONSUMER_KEY', defaultValue: '');

  /// Consumer secret for authenticating against WooCommerce.
  ///
  /// Provide a value at build time using:
  /// `flutter run --dart-define=WOO_CONSUMER_SECRET=cs_xxx`.
  static const String consumerSecret =
      String.fromEnvironment('WOO_CONSUMER_SECRET', defaultValue: '');

  static bool get hasWooCommerceCredentials =>
      consumerKey.isNotEmpty && consumerSecret.isNotEmpty;

  /// Basic authentication header expected by WooCommerce.
  static Map<String, String> get wooCommerceAuthHeaders {
    if (!hasWooCommerceCredentials) {
      return const {};
    }

    final encoded = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
    return {'Authorization': 'Basic $encoded'};
  }

  /// Query parameters for authenticating WooCommerce requests.
  static Map<String, String> get wooCommerceAuthQueryParameters {
    if (!hasWooCommerceCredentials) {
      return const {};
    }

    return {
      'consumer_key': consumerKey,
      'consumer_secret': consumerSecret,
    };
  }

  /// Helper for building a backend [Uri] with optional query parameters while
  /// skipping null values and automatically appending WooCommerce credentials.
  static Uri buildBackendUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$backendBaseUrl$normalizedPath');

    final sanitized = <String, String>{};
    if (queryParameters != null && queryParameters.isNotEmpty) {
      queryParameters.forEach((key, value) {
        if (value == null) return;
        sanitized[key] = value.toString();
      });
    }

    AppConfig.wooCommerceAuthQueryParameters.forEach((key, value) {
      sanitized.putIfAbsent(key, () => value);
    });

    if (sanitized.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: sanitized);
  }

  static const String jwtLoginUrl =
      "https://creditphoneqatar.com/wp-json/jwt-auth/v1/token";
}
