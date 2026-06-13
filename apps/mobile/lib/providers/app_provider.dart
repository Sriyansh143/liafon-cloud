import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  bool _isOnboardingComplete = false;
  bool _isLoggedIn = false;
  String? _userId;
  String? _userName;
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getters
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  ThemeMode get themeMode => _themeMode;
  
  // Initialize app state
  Future<void> initialize() async {
    await checkOnboardingStatus();
    await checkLoginStatus();
    await loadThemePreference();
  }
  
  // Check onboarding status
  Future<void> checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    notifyListeners();
  }
  
  // Complete onboarding
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    _isOnboardingComplete = true;
    notifyListeners();
  }
  
  // Check login status
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _userId = prefs.getString('user_id');
    _userName = prefs.getString('user_name');
    notifyListeners();
  }
  
  // Login user
  Future<void> login(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_name', userName);
    
    _isLoggedIn = true;
    _userId = userId;
    _userName = userName;
    notifyListeners();
  }
  
  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    notifyListeners();
  }
  
  // Load theme preference
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    _themeMode = mode;
    notifyListeners();
  }
  
  // Toggle theme
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}
