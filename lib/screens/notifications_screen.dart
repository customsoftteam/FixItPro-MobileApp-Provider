import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService.instance;

  final List<NotificationItem> _notifications = <NotificationItem>[];

  bool _loading = true;
  bool _loadingMore = false;
  bool _markingAllRead = false;

  int _page = 1;
  int _totalPages = 1;
  int _unreadCount = 0;

  String _activeFilter = 'all';
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage({int nextPage = 1, bool append = false}) async {
    setState(() {
      _error = null;
      _message = null;
      if (append) {
        _loadingMore = true;
      } else {
        _loading = true;
      }
    });

    try {
      final result = await _service.getNotifications(page: nextPage, limit: 20);
      if (!mounted) return;

      setState(() {
        if (append) {
          _notifications.addAll(result.notifications);
        } else {
          _notifications
            ..clear()
            ..addAll(result.notifications);
        }
        _page = result.page;
        _totalPages = result.pages;
        _unreadCount = result.unreadCount;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _reload() async {
    await _loadPage(nextPage: 1, append: false);
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;

    setState(() {
      _markingAllRead = true;
      _error = null;
    });

    try {
      await _service.markAllRead();
      if (!mounted) return;

      setState(() {
        for (var i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
        _unreadCount = 0;
        _message = 'All notifications marked as read';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _markingAllRead = false;
        });
      }
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;

    try {
      await _service.markRead(item.id);
      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere((entry) => entry.id == item.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
        _unreadCount = _notifications.where((entry) => !entry.isRead).length;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} • $hour:$minute';
  }

  List<NotificationItem> _filteredNotifications() {
    if (_activeFilter == 'booking') {
      return _notifications.where((item) => item.type == 'BOOKING_ASSIGNED' || item.type == 'BOOKING_UPDATED').toList();
    }

    if (_activeFilter == 'general') {
      return _notifications.where((item) => item.type == 'GENERAL').toList();
    }

    return _notifications;
  }

  String _typeLabel(String type) {
    return switch (type) {
      'BOOKING_ASSIGNED' || 'BOOKING_UPDATED' => 'Booking',
      _ => 'General',
    };
  }

  Color _typeColor(String type) {
    return switch (type) {
      'BOOKING_ASSIGNED' => const Color(0xFF2563EB),
      'BOOKING_UPDATED' => const Color(0xFF0EA5E9),
      _ => const Color(0xFF64748B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredNotifications();

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Notifications', style: Theme.of(context).textTheme.headlineMedium),
              ),
              OutlinedButton.icon(
                onPressed: (_unreadCount == 0 || _markingAllRead) ? null : _markAllRead,
                icon: _markingAllRead
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_read_outlined),
                label: const Text('Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$_unreadCount unread notifications'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _activeFilter == 'all',
                onSelected: (_) => setState(() => _activeFilter = 'all'),
              ),
              ChoiceChip(
                label: const Text('Bookings'),
                selected: _activeFilter == 'booking',
                onSelected: (_) => setState(() => _activeFilter = 'booking'),
              ),
              ChoiceChip(
                label: const Text('General'),
                selected: _activeFilter == 'general',
                onSelected: (_) => setState(() => _activeFilter = 'general'),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F9EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7E3B8)),
              ),
              child: Text(_message!, style: const TextStyle(color: Color(0xFF166534))),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B))),
            ),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 30), child: CircularProgressIndicator())),
          if (!_loading && filteredItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('No notifications found.'),
            ),
          ...filteredItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: item.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFEAF2FF),
                        child: Icon(
                          item.type.startsWith('BOOKING') ? Icons.assignment_turned_in_outlined : Icons.info_outline,
                          color: item.type.startsWith('BOOKING') ? const Color(0xFF0EA5E9) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                                  ),
                                ),
                                Chip(
                                  label: Text(_typeLabel(item.type)),
                                  side: BorderSide.none,
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  labelStyle: TextStyle(
                                    color: _typeColor(item.type),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (!item.isRead)
                                  const Chip(
                                    label: Text('New'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.message, style: const TextStyle(color: Color(0xFF475569))),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(item.createdAt),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => _markRead(item),
                                child: const Text('Mark read'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_page < _totalPages)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Center(
                child: OutlinedButton(
                  onPressed: _loadingMore
                      ? null
                      : () async {
                          await _loadPage(nextPage: _page + 1, append: true);
                        },
                  child: Text(_loadingMore ? 'Loading...' : 'Load More'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
