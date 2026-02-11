import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/auth/models/user_model.dart';
import 'package:parking_officer_app/features/auth/services/auth_service.dart';
import 'package:parking_officer_app/core/storage_manager.dart';
import 'dart:convert';

enum AuthStatus { authenticated, unauthenticated, authenticating, initial }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final storage = StorageManager();
    final userJson = await storage.getUserJson();

    if (userJson != null) {
      try {
        _user = User.fromJson(json.decode(userJson));
        _status = AuthStatus.authenticated;
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(phoneNumber, password);

    if (result['success']) {
      _user = result['user'];
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
