// Package imports:
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/backend/core/domain/user.dart';

void main() {
  group('User', () {
    test("avatarUrlOverride returns the avatarUrl with '&size=48' replaced with the size argument", () {
      const name = 'name';
      const avatarUrl = 'www.example.com/avatar?color=blue&size=48';
      const user = User(name: name, avatarUrl: avatarUrl);

      const size = '24';

      const expectedOverridenAvatarUrl = 'www.example.com/avatar?color=blue&size=$size';

      final actualOverridenAvatarUrl = user.avatarUrlOverride(size);

      expect(actualOverridenAvatarUrl, expectedOverridenAvatarUrl);
    });
  });
}
