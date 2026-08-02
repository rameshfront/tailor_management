import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

/// Provider for app-wide settings
class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _shopName = AppConstants.defaultShopName;
  String _ownerName = 'Owner';
  String _phone = '';
  String _address = '';
  String _currency = AppConstants.defaultCurrency;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  String get shopName => _shopName;
  String get ownerName => _ownerName;
  String get phone => _phone;
  String get address => _address;
  String get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;

  Future<void> loadSettings() async {
    final settings = await _db.getAllSettings();
    _shopName = settings[AppConstants.keyShopName] ?? AppConstants.defaultShopName;
    _ownerName = settings[AppConstants.keyOwnerName] ?? 'Owner';
    _phone = settings[AppConstants.keyPhone] ?? '';
    _address = settings[AppConstants.keyAddress] ?? '';
    _currency = settings[AppConstants.keyCurrency] ?? AppConstants.defaultCurrency;
    final theme = settings[AppConstants.keyThemeMode] ?? 'light';
    _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> updateSettings({
    required String shopName,
    required String ownerName,
    required String phone,
    required String address,
    required String currency,
  }) async {
    await _db.setSetting(AppConstants.keyShopName, shopName);
    await _db.setSetting(AppConstants.keyOwnerName, ownerName);
    await _db.setSetting(AppConstants.keyPhone, phone);
    await _db.setSetting(AppConstants.keyAddress, address);
    await _db.setSetting(AppConstants.keyCurrency, currency);
    _shopName = shopName;
    _ownerName = ownerName;
    _phone = phone;
    _address = address;
    _currency = currency;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _db.setSetting(
      AppConstants.keyThemeMode,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }
}
