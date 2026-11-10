import 'dart:convert';

import 'package:flutter/material.dart';

/// Hiển thị ảnh base64; nếu không có ảnh thì hiện chữ cái đầu của tên.
class UserAvatar extends StatelessWidget {
  final String base64Image;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.base64Image,
    required this.name,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (base64Image.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(base64Image)),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
    );
  }
}
