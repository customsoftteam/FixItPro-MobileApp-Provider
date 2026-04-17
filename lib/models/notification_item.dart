class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.bookingId,
    required this.bookingObjectId,
    required this.bookingStatus,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String bookingId;
  final String bookingObjectId;
  final String bookingStatus;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    String? bookingId,
    String? bookingObjectId,
    String? bookingStatus,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      bookingId: bookingId ?? this.bookingId,
      bookingObjectId: bookingObjectId ?? this.bookingObjectId,
      bookingStatus: bookingStatus ?? this.bookingStatus,
    );
  }
}

class NotificationPageResult {
  const NotificationPageResult({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.pages,
    required this.total,
  });

  final List<NotificationItem> notifications;
  final int unreadCount;
  final int page;
  final int pages;
  final int total;
}
