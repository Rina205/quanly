import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

/// Dùng chung cho Thêm (user == null) và Sửa (user != null).
class UserFormScreen extends StatefulWidget {
  final AppUser? user;
  final AppUser currentUser;
  const UserFormScreen({super.key, required this.currentUser, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UserService();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _hotenCtrl;
  final _passCtrl = TextEditingController();
  String _imageBase64 = '';
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _hotenCtrl = TextEditingController(text: widget.user?.hoten ?? '');
    _imageBase64 = widget.user?.hinhanh ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    // Thu nhỏ ảnh để chuỗi base64 không vượt giới hạn 1MB/document của Firestore
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    setState(() => _imageBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final email = _emailCtrl.text.trim();
    try {
      if (await _service.emailExists(email, exceptId: widget.user?.id)) {
        _showMsg('Email đã tồn tại');
        return;
      }
      if (_isEdit) {
        await _service.updateUser(
          widget.user!.id,
          actorEmail: widget.currentUser.email,
          email: email,
          hoten: _hotenCtrl.text.trim(),
          hinhanh: _imageBase64,
          matkhauMoi: _passCtrl.text,
        );
      } else {
        await _service.addUser(
          actorEmail: widget.currentUser.email,
          email: email,
          matkhau: _passCtrl.text,
          hoten: _hotenCtrl.text.trim(),
          hinhanh: _imageBase64,
        );
      }
      if (!mounted) return;
      _showMsg(_isEdit ? 'Đã cập nhật' : 'Đã thêm người dùng');
      Navigator.pop(context);
    } catch (e) {
      _showMsg('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!widget.currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không có quyền truy cập')),
        body: const Center(
          child: Text('Chỉ tài khoản quản trị viên được quản lý người dùng.'),
        ),
      );
    }
    if (widget.user?.isAdmin ?? false) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không thể chỉnh sửa tài khoản')),
        body: const Center(
          child: Text('Tài khoản admin không được chỉnh sửa.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Chỉnh sửa người dùng' : 'Thêm người dùng',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEdit ? 'Cập nhật thông tin' : 'Tạo tài khoản mới',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF202943),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Điền thông tin bên dưới để ${_isEdit ? 'cập nhật hồ sơ' : 'thêm người dùng vào hệ thống'}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF78829A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE9EDF5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFFEEF1FF),
                            backgroundImage: _imageBase64.isNotEmpty
                                ? MemoryImage(base64Decode(_imageBase64))
                                : null,
                            child: _imageBase64.isEmpty
                                ? Icon(Icons.person_rounded,
                                    size: 46, color: theme.colorScheme.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Chọn ảnh'),
                            ),
                            if (!kIsWeb)
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Chụp ảnh'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _hotenCtrl,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nhập họ tên'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            final ok = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.]+$')
                                .hasMatch(v?.trim() ?? '');
                            return ok ? null : 'Email không hợp lệ';
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            helperText: _isEdit
                                ? 'Để trống nếu không đổi mật khẩu'
                                : null,
                          ),
                          validator: (v) {
                            if (_isEdit && (v == null || v.isEmpty)) return null;
                            return (v == null || v.length < 6)
                                ? 'Mật khẩu tối thiểu 6 ký tự'
                                : null;
                          },
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(_saving ? 'Đang lưu...' : 'Lưu thông tin'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
