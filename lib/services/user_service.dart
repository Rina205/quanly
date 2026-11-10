import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../models/app_user.dart';

class UserService {
  final _col = FirebaseFirestore.instance.collection('users');

  void _requireAdmin(String actorEmail) {
    if (actorEmail.trim().toLowerCase() != AppUser.adminEmail) {
      throw StateError('Chỉ tài khoản ${AppUser.adminEmail} được quản lý người dùng');
    }
  }

  Future<void> _requireNotAdminTarget(String id) async {
    final doc = await _col.doc(id).get();
    if (AppUser.fromDoc(doc).isAdmin) {
      throw StateError('Không được sửa hoặc xóa tài khoản admin');
    }
  }

  void _requireNonReservedEmail(String email) {
    if (email.trim().toLowerCase() == AppUser.adminEmail) {
      throw StateError('Email này được dành riêng cho tài khoản admin');
    }
  }

  /// Băm mật khẩu trước khi lưu (chức năng nâng cao: bảo mật).
  static String hashPassword(String plain) =>
      sha256.convert(utf8.encode(plain)).toString();

  /// Danh sách người dùng, tự cập nhật realtime.
  Stream<List<AppUser>> watchUsers() => _col
      .orderBy('hoten')
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  Future<bool> emailExists(String email, {String? exceptId}) async {
    final q = await _col.where('email', isEqualTo: email).get();
    return q.docs.any((d) => d.id != exceptId);
  }

  Future<void> addUser({
    required String actorEmail,
    required String email,
    required String matkhau,
    required String hoten,
    required String hinhanh,
  }) {
    _requireAdmin(actorEmail);
    _requireNonReservedEmail(email);
    return _col.add({
      'email': email,
      'matkhau': hashPassword(matkhau),
      'hoten': hoten,
      'hinhanh': hinhanh,
    });
  }

  /// Nếu [matkhauMoi] rỗng thì giữ mật khẩu cũ.
  Future<void> updateUser(
    String id, {
    required String actorEmail,
    required String email,
    required String hoten,
    required String hinhanh,
    String matkhauMoi = '',
  }) async {
    _requireAdmin(actorEmail);
    await _requireNotAdminTarget(id);
    _requireNonReservedEmail(email);
    final data = <String, dynamic>{
      'email': email,
      'hoten': hoten,
      'hinhanh': hinhanh,
    };
    if (matkhauMoi.isNotEmpty) data['matkhau'] = hashPassword(matkhauMoi);
    await _col.doc(id).update(data);
  }

  Future<void> deleteUser(String id, {required String actorEmail}) async {
    _requireAdmin(actorEmail);
    await _requireNotAdminTarget(id);
    await _col.doc(id).delete();
  }

  /// Đăng nhập: tìm theo email rồi so sánh mật khẩu đã băm.
  Future<AppUser?> login(String email, String matkhau) async {
    final q = await _col.where('email', isEqualTo: email).limit(1).get();
    if (q.docs.isEmpty) return null;
    final user = AppUser.fromDoc(q.docs.first);
    return user.matkhau == hashPassword(matkhau) ? user : null;
  }

  /// Xuất toàn bộ collection ra JSON để nộp file cơ sở dữ liệu.
  Future<String> exportJson() async {
    final q = await _col.get();
    final data = {for (final d in q.docs) d.id: d.data()};
    return const JsonEncoder.withIndent('  ').convert({'users': data});
  }
}
