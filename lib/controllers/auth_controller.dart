import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  static const String _passwordKey = 'app_password';
  static const String _defaultPassword =
      '12345678'; // 8 haneli varsayılan şifre
  bool _isAuthenticated = false;
  Timer? _autoLockTimer;
  static const Duration _autoLockDuration = Duration(minutes: 5); // 5 dakika

  bool get isAuthenticated => _isAuthenticated;

  // Şifreyi al
  Future<String> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey) ?? _defaultPassword;
  }

  // Şifreyi ayarla
  Future<bool> setPassword(String newPassword) async {
    if (newPassword.length != 8) {
      return false; // 8 haneli olmalı
    }

    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_passwordKey, newPassword);
  }

  // Şifre doğrula
  Future<bool> validatePassword(String password) async {
    final correctPassword = await getPassword();
    if (password == correctPassword) {
      _isAuthenticated = true;
      _startAutoLockTimer();
      return true;
    }
    return false;
  }

  // Şifre değiştir
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Önce mevcut şifreyi doğrula
    final isValid = await validatePassword(currentPassword);
    if (!isValid) {
      return false; // Mevcut şifre yanlış
    }

    // Yeni şifreyi ayarla
    final success = await setPassword(newPassword);
    if (success) {
      // Şifre değiştirildikten sonra logout yap
      logout();
    }
    return success;
  }

  void logout() {
    _isAuthenticated = false;
    _stopAutoLockTimer();
  }

  void resetAuth() {
    _isAuthenticated = false;
    _stopAutoLockTimer();
  }

  // Otomatik kilitleme başlat
  void _startAutoLockTimer() {
    _stopAutoLockTimer(); // Önceki timer'ı durdur
    _autoLockTimer = Timer(_autoLockDuration, () {
      if (_isAuthenticated) {
        logout();
      }
    });
  }

  // Otomatik kilitleme durdur
  void _stopAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  // Kullanıcı aktivitesi - timer'ı sıfırla
  void userActivity() {
    if (_isAuthenticated) {
      _startAutoLockTimer();
    }
  }

  // Timer'ı sıfırla (kullanıcı aktif)
  void resetTimer() {
    if (_isAuthenticated) {
      _startAutoLockTimer();
    }
  }

  // Arkaplana alındığında kilitle
  void lockOnBackground() {
    if (_isAuthenticated) {
      logout();
    }
  }
}
