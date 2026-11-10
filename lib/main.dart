import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart'; // file này do lệnh `flutterfire configure` tự sinh
import 'models/app_user.dart';
import 'screens/login_screen.dart';
import 'screens/user_list_screen.dart';
import 'services/local_prefs.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalPrefs.init();
  themeModeNotifier.value = LocalPrefs.themeMode;

  // Ghi nhớ đăng nhập: nếu máy đã lưu ID tài khoản thì vào thẳng danh sách.
  AppUser? rememberedUser;
  final savedId = LocalPrefs.rememberedUserId;
  if (savedId != null) {
    try {
      rememberedUser = await UserService().getUserById(savedId);
    } catch (_) {
      rememberedUser = null; // lỗi mạng... thì cho đăng nhập lại
    }
    if (rememberedUser == null) await LocalPrefs.clearRememberedUser();
  }

  runApp(MyApp(rememberedUser: rememberedUser));
}

class MyApp extends StatelessWidget {
  final AppUser? rememberedUser;
  const MyApp({super.key, this.rememberedUser});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, _) => MaterialApp(
        title: 'Quản lý người dùng',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        home: rememberedUser != null
            ? UserListScreen(currentUser: rememberedUser!)
            : const LoginScreen(),
      ),
    );
  }
}
