import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fms/page/auth/presentation/login_page.dart';
import 'package:fms/core/services/navigation_service.dart';

class SessionService {
  SessionService._();

  static bool _isRedirecting = false;

  static Future<bool> handleUnauthorizedResponse(
    SharedPreferences prefs,
    http.Response response,
  ) async {
    if (!_isUnauthorized(response)) return false;
    await _clearSessionAndRedirect(prefs);
    return true;
  }

  static bool _isUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      return true;
    }

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final status = decoded['Status'] ?? decoded['status'];
        final message = decoded['Message'] ?? decoded['message'];
        if (status == 401) {
          if (message is String) {
            return message.toLowerCase().contains('unauthorized');
          }
          return true;
        }
      }
    } catch (_) {
      // ignore parsing errors and treat as not unauthorized
    }
    return false;
  }

  static Future<void> _clearSessionAndRedirect(SharedPreferences prefs) async {
    if (_isRedirecting) return;
    _isRedirecting = true;

    try {
      await prefs.clear();

      final navigator = NavigationService.navigatorKey.currentState;
      navigator?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } finally {
      _isRedirecting = false;
    }
  }
}
