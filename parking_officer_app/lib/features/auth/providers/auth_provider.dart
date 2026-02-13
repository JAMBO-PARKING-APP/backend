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
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      final storage = StorageManager();
      final userJson = await storage.getUserJson();

      if (userJson != null) {
        try {
          _user = User.fromJson(json.decode(userJson));
          _status = AuthStatus.authenticated;
        } catch (e) {
          debugPrint('[AuthProvider] Error parsing user JSON: $e');
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error in checkAuth: $e');
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    try {
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
    } catch (e) {
      debugPrint('[AuthProvider] Error in login: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'An error occurred during login. Please try again.';
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

  Future<bool> updateChatAvailability(bool available) async {
    try {
      final result = await _authService.updateProfile({
        'can_receive_chats': available,
      });
      if (result['success']) {
        _user = User(
          id: _user!.id,
          phone: _user!.phone,
          firstName: _user!.firstName,
          lastName: _user!.lastName,
          email: _user!.email,
          role: _user!.role,
          profilePhoto: _user!.profilePhoto,
          canReceiveChats: available,
        );
        notifyListeners();
        // Save to storage
        final storage = StorageManager();
        await storage.saveUserJson(
          json.encode({
            'id': _user!.id,
            'phone': _user!.phone,
            'first_name': _user!.firstName,
            'last_name': _user!.lastName,
            'email': _user!.email,
            'role': _user!.role,
            'profile_photo': _user!.profilePhoto,
            'can_receive_chats': _user!.canReceiveChats,
          }),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] Error updating chat availability: $e');
      return false;
    }
  }
}
