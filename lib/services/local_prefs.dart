import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu cài đặt NGAY TRÊN MÁY bằng shared_preferences,
/// không ghi gì vào Firestore (không thêm trường mới vào cơ sở dữ liệu).
class LocalPrefs {
  static const _kThemeMode = 'theme_mode';
  static const _kRememberedUserId = 'remembered_user_id';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Chế độ sáng / tối ----
  static ThemeMode get themeMode => switch (_prefs.getString(_kThemeMode)) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };

  static Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  // ---- Ghi nhớ đăng nhập: chỉ lưu ID tài khoản, KHÔNG lưu mật khẩu ----
  static String? get rememberedUserId => _prefs.getString(_kRememberedUserId);

  static Future<void> setRememberedUserId(String id) =>
      _prefs.setString(_kRememberedUserId, id);

  static Future<void> clearRememberedUser() =>
      _prefs.remove(_kRememberedUserId);
}
