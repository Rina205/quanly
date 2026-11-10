import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';
import 'user_form_screen.dart';

class UserListScreen extends StatefulWidget {
  final AppUser currentUser;
  const UserListScreen({super.key, required this.currentUser});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _service = UserService();
  String _keyword = '';

  bool get _isAdmin => widget.currentUser.isAdmin;

  Future<void> _confirmDelete(AppUser u) async {
    if (!_isAdmin) return;
    if (u.isAdmin) return;
    if (u.id == widget.currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa tài khoản đang đăng nhập')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa người dùng?'),
        content: Text('Xóa "${u.hoten}" (${u.email}) khỏi cơ sở dữ liệu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.deleteUser(u.id, actorEmail: widget.currentUser.email);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Đã xóa')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể xóa người dùng: $e')),
          );
        }
      }
    }
  }

  void _showDetail(AppUser u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(base64Image: u.hinhanh, name: u.hoten, radius: 60),
            const SizedBox(height: 16),
            Text(u.hoten, style: Theme.of(context).textTheme.titleLarge),
            Text(u.email),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson() async {
    final json = await _service.exportJson();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dữ liệu JSON'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(child: SelectableText(json)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã sao chép JSON')));
            },
            child: const Text('Sao chép'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Người dùng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Xuất JSON',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportJson,
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserFormScreen(currentUser: widget.currentUser),
                ),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Thêm'),
            )
          : null,
      body: StreamBuilder<List<AppUser>>(
        stream: _service.watchUsers(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          final allUsers = snap.data!;
          final admins = allUsers.where((u) => u.isAdmin);
          final admin = admins.isEmpty ? null : admins.first;
          final users = allUsers
              .where(
                (u) =>
                    !u.isAdmin &&
                    (u.hoten.toLowerCase().contains(_keyword) ||
                        u.email.toLowerCase().contains(_keyword)),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý tài khoản của bạn',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF78829A),
                      ),
                    ),
                    if (admin != null) ...[
                      const SizedBox(height: 14),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: const Color(0xFFEEF1FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFDCE3FF)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: UserAvatar(
                            base64Image: admin.hinhanh,
                            name: admin.hoten,
                            radius: 24,
                          ),
                          title: const Text(
                            'Quản trị viên',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(admin.email),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          onTap: () => _showDetail(admin),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm theo tên hoặc email',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) =>
                          setState(() => _keyword = v.toLowerCase()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Text(
                          _isAdmin
                              ? 'Chưa có người dùng. Bấm "Thêm" để tạo mới.'
                              : 'Chưa có người dùng.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final u = users[i];
                          return Card(
                            margin: EdgeInsets.zero,
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: Color(0xFFE9EDF5)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: UserAvatar(
                                base64Image: u.hinhanh,
                                name: u.hoten,
                                radius: 25,
                              ),
                              title: Text(
                                u.hoten,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(u.email),
                              ),
                              onTap: () => _showDetail(u),
                              trailing: _isAdmin
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Sửa',
                                          style: IconButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.primary,
                                          ),
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserFormScreen(
                                                currentUser: widget.currentUser,
                                                user: u,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Xóa',
                                          style: IconButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.error,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () => _confirmDelete(u),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
