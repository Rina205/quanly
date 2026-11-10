import 'package:flutter/material.dart';

import '../services/local_prefs.dart';

const _seed = Color(0xFF4263EB);

/// Chế độ giao diện hiện tại; đổi giá trị là cả app đổi theo.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

/// Chuyển qua lại sáng <-> tối và lưu lựa chọn trên máy.
void toggleThemeMode(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final next = isDark ? ThemeMode.light : ThemeMode.dark;
  themeModeNotifier.value = next;
  LocalPrefs.setThemeMode(next);
}

/// Nút đổi sáng/tối dùng chung cho các màn hình.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => toggleThemeMode(context),
    );
  }
}

/// Bảng màu riêng của app cho 2 chế độ sáng / tối.
class AppColors {
  final Color background;
  final Color card;
  final Color border;
  final Color title;
  final Color muted;
  final Color accentBg;
  final Color accentBorder;

  const AppColors._({
    required this.background,
    required this.card,
    required this.border,
    required this.title,
    required this.muted,
    required this.accentBg,
    required this.accentBorder,
  });

  static const light = AppColors._(
    background: Color(0xFFF5F7FC),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE9EDF5),
    title: Color(0xFF202943),
    muted: Color(0xFF78829A),
    accentBg: Color(0xFFEEF1FF),
    accentBorder: Color(0xFFDCE3FF),
  );

  static const dark = AppColors._(
    background: Color(0xFF10131C),
    card: Color(0xFF1A1F2B),
    border: Color(0xFF2A3142),
    title: Color(0xFFE7EAF3),
    muted: Color(0xFF9AA3B8),
    accentBg: Color(0xFF222B4A),
    accentBorder: Color(0xFF34407A),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    surface: c.card,
  );
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: c.background,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.card),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(c.border),
      enabledBorder: border(c.border),
      focusedBorder: border(scheme.primary, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
