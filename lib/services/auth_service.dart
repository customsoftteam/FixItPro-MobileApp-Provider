import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.provider,
    required this.isNewUser,
  });

  final String token;
  final Map<String, dynamic> provider;
  final bool isNewUser;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  factory AuthService() => instance;

  static const String _tokenKey = 'fixitpro_token';
  static const String _providerKey = 'fixitpro_provider';

  Future<Map<String, dynamic>> sendOtp({required String mobile}) async {
    final response = await ApiClient.instance.post(
      '/auth/send-otp',
      body: {'mobile': mobile},
    );

    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<AuthSession> verifyOtp({required String mobile, required String otp}) async {
    final response = await ApiClient.instance.post(
      '/auth/verify-otp',
      body: {'mobile': mobile, 'otp': otp},
    );

    final token = response['token']?.toString() ?? '';
    final provider = Map<String, dynamic>.from(response['provider'] as Map? ?? {});
    final isNewUser = response['isNewUser'] == true || response['isNewUser']?.toString() == 'true';

    if (token.isEmpty) {
      throw ApiClientException('Login failed', 500);
    }

    await setSession(token: token, provider: provider);

    return AuthSession(token: token, provider: provider, isNewUser: isNewUser);
  }

  Future<void> setSession({required String token, required Map<String, dynamic> provider}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_providerKey, jsonEncode(provider));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    if (!_looksLikeJwt(token)) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_providerKey);
      return null;
    }

    return token;
  }

  Future<Map<String, dynamic>?> getStoredProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_providerKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return null;
  }

  Future<void> completeOnboarding() async {
    // No-op locally; backend onboarding is handled in the provider profile flow.
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_providerKey);
  }

  bool _looksLikeJwt(String token) {
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }
}
