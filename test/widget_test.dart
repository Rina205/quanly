import 'package:flutter_test/flutter_test.dart';

import 'package:quanly_nguoidung/services/user_service.dart';

void main() {
  test('hashPassword băm SHA-256 ổn định', () {
    final h = UserService.hashPassword('123456');
    expect(h, UserService.hashPassword('123456'));
    expect(h.length, 64);
    expect(h, isNot('123456'));
  });
}
