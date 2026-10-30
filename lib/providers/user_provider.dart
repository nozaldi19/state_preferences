import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Latihan 4: UserProvider sekarang berupa ChangeNotifier (package provider).
class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  int get visitCount => _visitCount;
  List<String> get favorites => List.unmodifiable(_favorites);

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final visit = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visit);

    _user = User(
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      isLoggedIn: prefs.getBool('is_logged_in') ?? false,
    );
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _visitCount = visit;
    _favorites = prefs.getStringList('favorites') ?? [];
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> updateUser(User newUser) async {
    final prefs = await SharedPreferences.getInstance();

    final dangerous = RegExp(r'[<>{}]|javascript:', caseSensitive: false);
    if (dangerous.hasMatch(newUser.name)) {
      return 'Nama mengandung karakter berbahaya (<, >, {, }, javascript:)';
    }

    final registered = prefs.getStringList('registered_emails') ??
        ['admin@example.com', 'test@example.com'];
    final newEmail = newUser.email.toLowerCase();
    final oldEmail = (prefs.getString('user_email') ?? '').toLowerCase();
    if (newEmail != oldEmail && registered.contains(newEmail)) {
      return 'Email sudah digunakan akun lain';
    }
    registered.remove(oldEmail);
    registered.add(newEmail);
    await prefs.setStringList('registered_emails', registered);

    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    _user = newUser;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    _user = _user.copyWith(name: '', isLoggedIn: false);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> addFavorite(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = [..._favorites, item];
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }

  Future<void> removeFavorite(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = _favorites.where((e) => e != item).toList();
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }
}