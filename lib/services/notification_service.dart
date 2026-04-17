import '../models/notification_item.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<NotificationPageResult> getNotifications({int page = 1, int limit = 20}) async {
    final response = await ApiClient.instance.get(
      '/notifications',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final pagination = Map<String, dynamic>.from(response['pagination'] as Map? ?? {});
    final notifications = (response['notifications'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _parseNotification(Map<String, dynamic>.from(item)))
        .toList();

    return NotificationPageResult(
      notifications: notifications,
      unreadCount: (response['unreadCount'] as num?)?.toInt() ?? 0,
      page: (pagination['page'] as num?)?.toInt() ?? page,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? notifications.length,
    );
  }

  Future<int> getUnreadCount() async {
    final firstPage = await getNotifications(page: 1, limit: 1);
    return firstPage.unreadCount;
  }

  Future<void> markRead(String notificationId) async {
    await ApiClient.instance.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await ApiClient.instance.patch('/notifications/read-all');
  }

  NotificationItem _parseNotification(Map<String, dynamic> item) {
    final meta = Map<String, dynamic>.from(item['meta'] as Map? ?? {});

    return NotificationItem(
      id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
      title: item['title']?.toString() ?? 'Notification',
      message: item['message']?.toString() ?? '',
      type: item['type']?.toString() ?? 'GENERAL',
      createdAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isRead: item['isRead'] == true,
      bookingId: meta['bookingId']?.toString() ?? '',
      bookingObjectId: meta['bookingObjectId']?.toString() ?? '',
      bookingStatus: meta['status']?.toString() ?? '',
    );
  }
}
