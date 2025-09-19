import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Base URL for the WooCommerce REST API.
  static const String backendBaseUrl =
      "https://creditphoneqatar.com/wp-json/wc/v3";

  static String get _consumerKeyFromDartDefine => const String.fromEnvironment(
        'WOO_CONSUMER_KEY',
        defaultValue: '',
      );

  static String get _consumerSecretFromDartDefine =>
      const String.fromEnvironment(
        'WOO_CONSUMER_SECRET',
        defaultValue: '',
      );

  /// Consumer key for authenticating against WooCommerce.
  ///
  /// Values are loaded from the runtime environment using [flutter_dotenv]
  /// and fall back to a `--dart-define` flag so CI can inject secrets without
  /// creating files on disk.
  static String get consumerKey {
    final envValue = dotenv.env['WOO_CONSUMER_KEY']?.trim();
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    return _consumerKeyFromDartDefine;
  }

  /// Consumer secret for authenticating against WooCommerce.
  ///
  /// Values are loaded from the runtime environment using [flutter_dotenv]
  /// and fall back to a `--dart-define` flag so CI can inject secrets without
  /// creating files on disk.
  static String get consumerSecret {
    final envValue = dotenv.env['WOO_CONSUMER_SECRET']?.trim();
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    return _consumerSecretFromDartDefine;
  }

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
