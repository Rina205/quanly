import 'package:cloud_firestore/cloud_firestore.dart';

/// Chỉ đúng 4 trường theo đề: email, matkhau, hoten, hinhanh.
/// `id` là ID của document Firestore, không phải một trường dữ liệu.
class AppUser {
  static const adminEmail = 'phuongnt7925@gmail.com';

  final String id;
  final String email;
  final String matkhau; // lưu dạng đã băm SHA-256
  final String hoten;
  final String hinhanh; // ảnh dạng chuỗi base64

  bool get isAdmin => email.trim().toLowerCase() == adminEmail;

  AppUser({
    required this.id,
    required this.email,
    required this.matkhau,
    required this.hoten,
    required this.hinhanh,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      email: d['email'] ?? '',
      matkhau: d['matkhau'] ?? '',
      hoten: d['hoten'] ?? '',
      hinhanh: d['hinhanh'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'matkhau': matkhau,
        'hoten': hoten,
        'hinhanh': hinhanh,
      };
}
