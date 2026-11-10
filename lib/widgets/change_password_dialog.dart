import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// Hộp thoại đổi mật khẩu cho tài khoản đang đăng nhập.
/// Trả về true nếu đổi thành công.
Future<bool?> showChangePasswordDialog(BuildContext context, AppUser user) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePasswordDialog(user: user),
    );

class _ChangePasswordDialog extends StatefulWidget {
  final AppUser user;
  const _ChangePasswordDialog({required this.user});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = UserService();
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _oldError;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _oldError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ok = await _service.changeOwnPassword(
        widget.user.id,
        matkhauCu: _oldCtrl.text,
        matkhauMoi: _newCtrl.text,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _oldError = 'Mật khẩu hiện tại không đúng');
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _passField({
    required TextEditingController ctrl,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
    String? errorText,
    String? Function(String?)? validator,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: ctrl,
      stylusHandwritingEnabled: false,
      obscureText: hidden,
      textInputAction: action,
      onFieldSubmitted: action == TextInputAction.done ? (_) => _submit() : null,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(hidden
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.user.email,
                  style: TextStyle(color: AppColors.of(context).muted),
                ),
                const SizedBox(height: 16),
                _passField(
                  ctrl: _oldCtrl,
                  label: 'Mật khẩu hiện tại',
                  hidden: _hideOld,
                  onToggle: () => setState(() => _hideOld = !_hideOld),
                  errorText: _oldError,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Nhập mật khẩu hiện tại'
                      : null,
                ),
                const SizedBox(height: 12),
                _passField(
                  ctrl: _newCtrl,
                  label: 'Mật khẩu mới',
                  hidden: _hideNew,
                  onToggle: () => setState(() => _hideNew = !_hideNew),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Mật khẩu tối thiểu 6 ký tự';
                    }
                    if (v == _oldCtrl.text) {
                      return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _passField(
                  ctrl: _confirmCtrl,
                  label: 'Nhập lại mật khẩu mới',
                  hidden: _hideConfirm,
                  onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                  action: TextInputAction.done,
                  validator: (v) =>
                      v != _newCtrl.text ? 'Mật khẩu nhập lại không khớp' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Đang lưu...' : 'Đổi mật khẩu'),
        ),
      ],
    );
  }
}
