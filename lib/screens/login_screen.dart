import 'package:flutter/material.dart';

import '../services/local_prefs.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'user_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _service = UserService();
  bool _loading = false;
  bool _hidePass = true;
  bool _remember = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _service.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email hoặc mật khẩu không đúng')),
        );
      } else {
        // Chỉ lưu ID tài khoản trên máy (shared_preferences), không lưu mật khẩu.
        if (_remember) {
          await LocalPrefs.setRememberedUserId(user.id);
        } else {
          await LocalPrefs.clearRememberedUser();
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserListScreen(currentUser: user)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(actions: const [ThemeToggleButton()]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: c.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D243B73),
                    blurRadius: 32,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: c.accentBg,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Icon(Icons.admin_panel_settings_rounded,
                            color: theme.colorScheme.primary, size: 32),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Chào mừng trở lại',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.title,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để tiếp tục quản lý người dùng.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: c.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      stylusHandwritingEnabled: false,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Email không hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      stylusHandwritingEnabled: false,
                      controller: _passCtrl,
                      obscureText: _hidePass,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hidePass ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          icon: Icon(_hidePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _hidePass = !_hidePass),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? false),
                      title: const Text('Ghi nhớ đăng nhập'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ))
                          : const Text('Đăng nhập'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Khu vực quản trị an toàn',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
