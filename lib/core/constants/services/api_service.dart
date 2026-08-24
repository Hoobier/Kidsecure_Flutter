import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// lib/core/constants/services/api_service.dart

/// Thrown for any non-2xx response from the Laravel API. `message` is
/// already the friendly, user-facing string from the backend
/// (e.g. "Your session has expired. Please log in again.") — safe to
/// show directly in a SnackBar without translation.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Talks to the Laravel backend's /api/app/* endpoints, authenticated with
/// the parent's Firebase ID token (see VerifyFirebaseToken middleware).
/// Separate from FirestoreService, which reads real-time status straight
/// from Firebase Realtime Database — this service is for anything that
/// writes to, or needs validation from, the Laravel/MongoDB source of truth.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Swappable per build/run via --dart-define=API_BASE_URL=...
  /// Defaults to the Android emulator's alias for the host machine's
  /// localhost (10.0.2.2), since 127.0.0.1 inside the emulator refers to
  /// the emulator itself, not your dev machine running `php artisan serve`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kidsecure-backend.onrender.com/api',
  );

  Future<String> _authHeader() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException('Not logged in.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw ApiException('Unable to verify your login. Please log in again.');
    }
    return 'Bearer $token';
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = response.body.isEmpty
          ? {}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message =
        body['message'] as String? ?? 'Something went wrong. Please try again.';
    throw ApiException(message, response.statusCode);
  }

  /// GET /api/app/me — parent profile + linked children.
  Future<Map<String, dynamic>> getMe() async {
    final auth = await _authHeader();
    final response = await http.get(
      Uri.parse('$baseUrl/app/me'),
      headers: {'Authorization': auth, 'Accept': 'application/json'},
    );
    return _decode(response);
  }

  /// PATCH /api/app/me — update own name/phone. Pass only the fields
  /// that changed; omitted fields are left untouched server-side.
  Future<Map<String, dynamic>> updateMe({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final auth = await _authHeader();
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phone != null) body['phone'] = phone;

    final response = await http.patch(
      Uri.parse('$baseUrl/app/me'),
      headers: {
        'Authorization': auth,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  /// PATCH /api/app/notifications — persists the toggle server-side so it
  /// survives reinstall/new device, instead of living only in
  /// SharedPreferences on one phone.
  Future<bool> updateNotifications(bool enabled) async {
    final auth = await _authHeader();
    final response = await http.patch(
      Uri.parse('$baseUrl/app/notifications'),
      headers: {
        'Authorization': auth,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'enabled': enabled}),
    );
    final data = _decode(response);
    return data['notificationsEnabled'] as bool? ?? enabled;
  }
}
