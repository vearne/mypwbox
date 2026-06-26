import 'package:flutter_test/flutter_test.dart';
import 'package:mypwbox/password.dart';

void main() {
  group('Password model', () {
    test('toMap and fromMap round-trip', () {
      final password = Password(
        id: 1,
        title: 'Test Title',
        account: 'test@example.com',
        password: 'secret123',
        comment: 'A test comment',
        createdAt: DateTime(2024, 1, 15, 10, 30, 0),
        updatedAt: DateTime(2024, 1, 16, 12, 0, 0),
      );

      final map = password.toMap();
      final restored = Password.fromMap(map);

      expect(restored.id, 1);
      expect(restored.title, 'Test Title');
      expect(restored.account, 'test@example.com');
      expect(restored.password, 'secret123');
      expect(restored.comment, 'A test comment');
      expect(restored.createdAt, DateTime(2024, 1, 15, 10, 30, 0));
      expect(restored.updatedAt, DateTime(2024, 1, 16, 12, 0, 0));
    });

    test('copyWith preserves unmodified fields', () {
      final password = Password(
        title: 'Original',
        account: 'user@example.com',
        password: 'pass123',
        comment: 'comment',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final copied = password.copyWith(password: 'newpass');

      expect(copied.title, 'Original');
      expect(copied.password, 'newpass');
      expect(copied.account, 'user@example.com');
    });

    test('fromMap handles null comment', () {
      final map = <String, dynamic>{
        'id': 1,
        'title': 'Test',
        'account': 'acc',
        'password': 'pwd',
        'comment': null,
        'created_at': '2024-01-15T10:30:00.000',
        'updated_at': '2024-01-15T10:30:00.000',
      };

      final password = Password.fromMap(map);
      expect(password.comment, '');
    });
  });
}
