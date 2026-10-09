import 'package:intl/intl.dart';

/// Formatter for dates, timestamps, and presence states in ChatFlow
class ChatDateUtils {
  /// Formats a message time (e.g., "10:42 PM")
  static String formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat.jm().format(dateTime);
  }

  /// Formats date separator for chat screen (e.g., "Today", "Yesterday", "October 2, 2026")
  static String formatDateSeparator(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (dateTime.year == now.year) {
      return DateFormat('MMMM d').format(dateTime);
    } else {
      return DateFormat('MMMM d, y').format(dateTime);
    }
  }

  /// Formats chat list tile preview timestamp (e.g., "10:42 AM", "Yesterday", "Oct 2")
  static String formatChatListTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final diffDays = today.difference(date).inDays;

    if (diffDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (diffDays < 7 && diffDays > 0) {
      return DateFormat('EEEE').format(dateTime); // e.g. Monday
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MM/dd/yy').format(dateTime);
    }
  }

  /// Formats user presence: "Online", "Last seen 5m ago", "Last seen today at 4:30 PM", etc.
  static String formatLastSeen({required bool isOnline, DateTime? lastSeen}) {
    if (isOnline) {
      return 'Online';
    }
    if (lastSeen == null) {
      return 'Offline';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == lastSeen.day) {
      return 'Last seen today at ${DateFormat.jm().format(lastSeen)}';
    } else if (difference.inDays < 2 || (now.day - lastSeen.day == 1 && difference.inHours < 48)) {
      return 'Last seen yesterday at ${DateFormat.jm().format(lastSeen)}';
    } else {
      return 'Last seen ${DateFormat('MMM d').format(lastSeen)} at ${DateFormat.jm().format(lastSeen)}';
    }
  }

  /// Returns true if two timestamps fall on different calendar days
  static bool isDifferentDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return true;
    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }
}
