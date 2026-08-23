import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isLoading = true;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  /// Called once at app startup to restore a saved session, if any.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? prefs.getString('token');
    final userJsonString = prefs.getString('user');
    if (token != null && userJsonString != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(userJsonString));
      } catch (_) {
        _user = null;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setSession(String token, Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(userJson));
    _user = AppUser.fromJson(userJson);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final updatedJson = await ApiService().getMe();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedJson));
      _user = AppUser.fromJson(updatedJson);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    notifyListeners();
  }
}
