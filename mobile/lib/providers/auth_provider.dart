import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<bool> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await _storage.read(key: 'token');
      if (_token != null) {
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isAuthenticated = false;
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      _token = response['token'];
      _user = response['user'];
      _isAuthenticated = true;
      await _storage.write(key: 'token', value: _token);
    } catch (e) {
      _isAuthenticated = false;
      _token = null;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
    String username,
    String password,
    String email,
    String firstName,
    String lastName,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        username,
        password,
        email,
        firstName,
        lastName,
      );
      _token = response['token'];
      _user = response['user'];
      _isAuthenticated = true;
      await _storage.write(key: 'token', value: _token);
    } catch (e) {
      _isAuthenticated = false;
      _token = null;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } finally {
      await _storage.delete(key: 'token');
      _isAuthenticated = false;
      _token = null;
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
} 