import 'package:chatflow/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatDateUtils Tests', () {
    test('formatMessageTime handles null and valid DateTime', () {
      expect(ChatDateUtils.formatMessageTime(null), '');
      final time = DateTime(2026, 10, 2, 14, 30);
      final formatted = ChatDateUtils.formatMessageTime(time);
      expect(formatted, contains('2:30'));
      expect(formatted, contains('PM'));
    });

    test('formatDateSeparator detects Today and Yesterday', () {
      final now = DateTime.now();
      expect(ChatDateUtils.formatDateSeparator(now), 'Today');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(ChatDateUtils.formatDateSeparator(yesterday), 'Yesterday');
    });

    test('formatLastSeen handles online status and last seen times', () {
      expect(ChatDateUtils.formatLastSeen(isOnline: true), 'Online');
      expect(ChatDateUtils.formatLastSeen(isOnline: false, lastSeen: null), 'Offline');

      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(ChatDateUtils.formatLastSeen(isOnline: false, lastSeen: fiveMinAgo), 'Last seen 5m ago');
    });

    test('isDifferentDay correctly identifies day boundaries', () {
      final day1 = DateTime(2026, 10, 2, 10, 0);
      final day1Later = DateTime(2026, 10, 2, 22, 0);
      final day2 = DateTime(2026, 10, 3, 1, 0);

      expect(ChatDateUtils.isDifferentDay(day1, day1Later), isFalse);
      expect(ChatDateUtils.isDifferentDay(day1, day2), isTrue);
    });
  });
}
