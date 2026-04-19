import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/booking_item.dart';
import '../services/api_client.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';
import 'service_workflow_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingService _bookingService = BookingService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<BookingItem> _bookings = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String? _message;
  String _activeTab = 'all';
  String _searchText = '';
  String _actionBookingId = '';
  Timer? _timer;

  final List<_StatusTab> _statusTabs = const [
    _StatusTab(key: 'all', label: 'All', icon: Icons.assignment_ind_outlined),
    _StatusTab(key: 'assigned', label: 'Assigned', icon: Icons.assignment_ind_outlined),
    _StatusTab(key: 'accepted', label: 'Accepted', icon: Icons.verified_user_outlined),
    _StatusTab(key: 'paused', label: 'Paused', icon: Icons.pause_circle_outline_rounded),
    _StatusTab(key: 'completed', label: 'Completed', icon: Icons.done_all_outlined),
    _StatusTab(key: 'rejected', label: 'Rejected', icon: Icons.highlight_off_outlined),
  ];

  final Set<String> _reachedLocationBookingIds = <String>{};

  static const Set<String> _ongoingStatuses = {
    'accepted',
    'in_progress',
    'paused',
    'otp_sent',
  };

  final Map<String, _StatusStyle> _statusStyle = const {
    'pending': _StatusStyle(bg: Color(0xFFFFF7E8), fg: Color(0xFFB45309), border: Color(0xFFFCD9A5), label: 'Pending Approval', icon: Icons.hourglass_empty_outlined),
    'assigned': _StatusStyle(bg: Color(0xFFEFF6FF), fg: Color(0xFF1D4ED8), border: Color(0xFFBFDBFE), label: 'Assigned', icon: Icons.assignment_ind_outlined),
    'accepted': _StatusStyle(bg: Color(0xFFECFEFF), fg: Color(0xFF0E7490), border: Color(0xFFBAE6FD), label: 'Accepted', icon: Icons.verified_user_outlined),
    'in_progress': _StatusStyle(bg: Color(0xFFEEF2FF), fg: Color(0xFF4338CA), border: Color(0xFFC7D2FE), label: 'In Progress', icon: Icons.play_arrow_rounded),
    'paused': _StatusStyle(bg: Color(0xFFFFF7ED), fg: Color(0xFFC2410C), border: Color(0xFFFED7AA), label: 'Paused', icon: Icons.pause_circle_outline_rounded),
    'otp_sent': _StatusStyle(bg: Color(0xFFFEF3C7), fg: Color(0xFF92400E), border: Color(0xFFFDE68A), label: 'OTP Sent', icon: Icons.task_alt_outlined),
    'completed': _StatusStyle(bg: Color(0xFFECFDF3), fg: Color(0xFF15803D), border: Color(0xFFBBF7D0), label: 'Completed', icon: Icons.done_all_outlined),
    'rejected': _StatusStyle(bg: Color(0xFFFEF2F2), fg: Color(0xFFB91C1C), border: Color(0xFFFECACA), label: 'Rejected', icon: Icons.highlight_off_outlined),
    'cancelled': _StatusStyle(bg: Color(0xFFF8FAFC), fg: Color(0xFF475569), border: Color(0xFFCBD5E1), label: 'Cancelled', icon: Icons.cancel_outlined),
  };

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings({bool silent = false}) async {
    setState(() {
      if (silent) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      final data = await _bookingService.getBookings();
      if (!mounted) return;
      setState(() {
        _bookings = data;
        _reachedLocationBookingIds.removeWhere(
          (bookingId) => !_bookings.any(
            (booking) => booking.id == bookingId && booking.status.trim().toLowerCase() == 'accepted',
          ),
        );
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to fetch bookings';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _runAction({
    required String bookingId,
    required Future<void> Function() action,
    required String successText,
    required String fallbackError,
    Future<void> Function()? onSuccess,
  }) async {
    setState(() {
      _actionBookingId = bookingId;
      _message = null;
      _error = null;
    });

    try {
      await action();
      if (!mounted) return;
      setState(() {
        _message = successText;
      });
      await _loadBookings(silent: true);
      if (onSuccess != null) {
        await onSuccess();
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = _resolveError(err, fallbackError);
      });
    } finally {
      if (mounted) {
        setState(() {
          _actionBookingId = '';
        });
      }
    }
  }

  String _resolveError(Object err, String fallback) {
    if (err is ApiClientException && err.message.isNotEmpty) {
      return err.message;
    }
    return fallback;
  }

  Future<void> _openWorkflowDialog(BookingItem booking) async {
    final workflowBookingId = booking.backendId.isEmpty ? booking.id : booking.backendId;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceWorkflowScreen(
          bookingId: workflowBookingId,
          bookingCode: booking.id,
          bookingService: _bookingService,
        ),
      ),
    );

    if (updated == true) {
      await _loadBookings(silent: true);
    }
  }

  Future<void> _openDetailsScreen(BookingItem booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} • $hour:$minute';
  }

  String _formatCurrency(double value) {
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  String _formatServiceDuration(BookingItem booking) {
    final startTime = booking.serviceStartTime;
    if (startTime == null) return '00:00:00';

    var totalSeconds = DateTime.now().difference(startTime).inSeconds - booking.pausedDurationSeconds;
    if (booking.status.trim().toLowerCase() == 'paused' && booking.pauseStartedAt != null) {
      totalSeconds -= DateTime.now().difference(booking.pauseStartedAt!).inSeconds;
    }

    if (totalSeconds < 0) totalSeconds = 0;

    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _markReachedLocation(String bookingId) {
    setState(() {
      _reachedLocationBookingIds.add(bookingId);
      _message = 'Reached location marked. Click Start Service to continue the workflow.';
      _error = null;
    });
  }

  List<BookingItem> _visibleBookings() {
    final query = _searchText.trim().toLowerCase();
    return _bookings.where((booking) {
      final status = booking.status.trim().toLowerCase();
      final tabMatch = _activeTab == 'all' || status == _activeTab;
      if (!tabMatch) return false;
      if (query.isEmpty) return true;

      final haystack = '${booking.id} ${booking.customerName} ${booking.serviceName} ${booking.address} $status'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  bool _isOngoingStatus(String status) {
    return _ongoingStatuses.contains(status.trim().toLowerCase());
  }

  Future<void> _clearOngoingBookings() async {
    final ongoingCount = _bookings.where((booking) => _isOngoingStatus(booking.status)).length;
    if (ongoingCount == 0) {
      setState(() {
        _message = 'No ongoing bookings to clear.';
        _error = null;
      });
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Ongoing Bookings'),
        content: Text('Clear $ongoingCount ongoing booking(s) from this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (shouldClear != true || !mounted) {
      return;
    }

    setState(() {
      _bookings = _bookings.where((booking) => !_isOngoingStatus(booking.status)).toList();
      _reachedLocationBookingIds.removeWhere(
        (bookingId) => !_bookings.any((booking) => booking.id == bookingId),
      );
      _message = '$ongoingCount ongoing booking(s) cleared from view.';
      _error = null;
      if (_activeTab != 'all' && _activeTab != 'assigned' && _activeTab != 'completed' && _activeTab != 'rejected') {
        _activeTab = 'all';
      }
    });
  }

  Map<String, int> _tabCounts() {
    final counts = <String, int>{'all': _bookings.length};
    for (final tab in _statusTabs) {
      if (tab.key != 'all') {
        counts[tab.key] = 0;
      }
    }

    for (final booking in _bookings) {
      final key = booking.status.trim().toLowerCase();
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<DropdownMenuItem<String>> _buildStatusFilterItems(Map<String, int> counts) {
    return _statusTabs
        .map(
          (tab) => DropdownMenuItem<String>(
            value: tab.key,
            child: Row(
              children: [
                Icon(tab.icon, size: 18),
                const SizedBox(width: 8),
                Text('${tab.label} (${counts[tab.key] ?? 0})'),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _statusChip(String status) {
    final style = _statusStyle[status] ??
        const _StatusStyle(
          bg: Color(0xFFF8FAFC),
          fg: Color(0xFF475569),
          border: Color(0xFFCBD5E1),
          label: 'Unknown',
          icon: Icons.help_outline,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.fg, size: 16),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: TextStyle(color: style.fg, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(BookingItem booking) {
    final actionBookingId = booking.backendId.isEmpty ? booking.id : booking.backendId;
    final status = booking.status.trim().toLowerCase();
    final canAcceptReject = status == 'assigned';
    final hasReachedLocation = _reachedLocationBookingIds.contains(booking.id);
    final showAcceptButton = status == 'assigned' || status == 'accepted';
    final acceptDisabled = status == 'accepted' || _actionBookingId.isNotEmpty;
    final canStart = status == 'accepted' && hasReachedLocation;
    final showReachedLocation = status == 'accepted';
    final canPause = status == 'in_progress';
    final canResume = status == 'paused';
    final canContinueFlow = status == 'in_progress' || status == 'otp_sent';
    final actionLoading = _actionBookingId == actionBookingId;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: math.max(120, constraints.maxWidth - 120)),
                            child: Text(
                              booking.id,
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _statusChip(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        booking.amount == 0 ? 'Amount not available' : _formatCurrency(booking.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF0F172A)),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                booking.id,
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _statusChip(status),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking.amount == 0 ? 'Amount not available' : _formatCurrency(booking.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                const SizedBox(height: 4),
                Text(_formatDateTime(booking.scheduledAt), style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(booking.address, style: const TextStyle(color: Color(0xFF64748B))),
                if (canContinueFlow) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Timer: ${_formatServiceDuration(booking)}',
                    style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w800),
                  ),
                ],
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: booking.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${booking.completedSteps}/${booking.steps.length} workflow steps complete'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (showReachedLocation)
                      ElevatedButton.icon(
                        onPressed: hasReachedLocation || _actionBookingId.isNotEmpty
                            ? null
                            : () => _markReachedLocation(booking.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasReachedLocation ? const Color(0xFFFEF3C7) : const Color(0xFFF59E0B),
                          foregroundColor: hasReachedLocation ? const Color(0xFFA16207) : Colors.white,
                        ),
                        icon: const Icon(Icons.room_outlined, size: 18),
                        label: Text(hasReachedLocation ? 'Reached Location' : 'Mark Reached Location'),
                      ),
                    if (showAcceptButton)
                      ElevatedButton.icon(
                        onPressed: acceptDisabled
                            ? null
                            : () => _runAction(
                                  bookingId: actionBookingId,
                                  action: () => _bookingService.acceptBooking(actionBookingId),
                                  successText: 'Booking accepted',
                                  fallbackError: 'Failed to accept booking',
                                ),
                        icon: actionLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Accept'),
                      ),
                    if (canAcceptReject)
                      ElevatedButton.icon(
                        onPressed: _actionBookingId.isNotEmpty
                            ? null
                            : () => _runAction(
                                  bookingId: actionBookingId,
                                  action: () => _bookingService.rejectBooking(actionBookingId),
                                  successText: 'Booking rejected',
                                  fallbackError: 'Failed to reject booking',
                                ),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        icon: actionLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.highlight_off_outlined, size: 18),
                        label: const Text('Reject'),
                      ),
                    if (canStart)
                      ElevatedButton.icon(
                        onPressed: _actionBookingId.isNotEmpty
                            ? null
                            : () => _runAction(
                                  bookingId: actionBookingId,
                                  action: () => _bookingService.startService(actionBookingId),
                                  successText: 'Service started',
                                  fallbackError: 'Failed to start service',
                                  onSuccess: () => _openWorkflowDialog(booking),
                                ),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
                        icon: actionLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start Service'),
                      ),
                    if (canPause)
                      ElevatedButton.icon(
                        onPressed: _actionBookingId.isNotEmpty
                            ? null
                            : () => _runAction(
                                  bookingId: actionBookingId,
                                  action: () => _bookingService.pauseService(actionBookingId),
                                  successText: 'Service paused',
                                  fallbackError: 'Failed to pause service',
                                ),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                        icon: actionLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.pause_circle_outline_rounded, size: 18),
                        label: const Text('Pause Service'),
                      ),
                    if (canResume)
                      ElevatedButton.icon(
                        onPressed: _actionBookingId.isNotEmpty
                            ? null
                            : () => _runAction(
                                  bookingId: actionBookingId,
                                  action: () => _bookingService.resumeService(actionBookingId),
                                  successText: 'Service resumed',
                                  fallbackError: 'Failed to resume service',
                                ),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        icon: actionLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Resume Service'),
                      ),
                    if (canContinueFlow)
                      ElevatedButton.icon(
                        onPressed: () => _openWorkflowDialog(booking),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA)),
                        icon: const Icon(Icons.task_alt_outlined, size: 18),
                        label: const Text('Continue Workflow'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _openDetailsScreen(booking);
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openDetailsDialog(BookingItem booking) {
    final status = booking.status.trim().toLowerCase();
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = math.min(680.0, width - 24);

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(booking.id, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Name: ${booking.customerName}'),
                Text('Mobile: ${booking.customerMobile.isEmpty ? 'Not available' : booking.customerMobile}'),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Service Details', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Service: ${booking.serviceName}'),
                Text('Schedule: ${_formatDateTime(booking.scheduledAt)}'),
                Text('Address: ${booking.address}'),
                Text('Notes: ${booking.notes.isEmpty ? 'No notes provided' : booking.notes}'),
                Text('Current Status: ${_statusStyle[status]?.label ?? 'Unknown'}'),
                Text('Timer: ${_formatServiceDuration(booking)}'),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Pricing and Payment', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Amount: ${_formatCurrency(booking.amount)}'),
                Text('Payment Method: ${booking.paymentMethod}'),
                Text('Payment Status: ${booking.paymentStatus}'),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Timeline', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Created: ${booking.createdAt == null ? 'Not available' : _formatDateTime(booking.createdAt!)}'),
                Text('Service Start: ${booking.serviceStartTime == null ? 'Not available' : _formatDateTime(booking.serviceStartTime!)}'),
                Text('Service End: ${booking.serviceEndTime == null ? 'Not available' : _formatDateTime(booking.serviceEndTime!)}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleBookings = _visibleBookings();
    final tabCounts = _tabCounts();
    final pageWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = pageWidth >= 1200
      ? 24.0
      : pageWidth >= 700
        ? 16.0
        : 12.0;

    if (_loading) {
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load bookings. Please sign in again and make sure the backend is running.\n\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadBookings(silent: true),
      child: Scrollbar(
        child: ListView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              final clearButton = OutlinedButton.icon(
                onPressed: (_loading || _refreshing || _actionBookingId.isNotEmpty) ? null : _clearOngoingBookings,
                icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                label: const Text('Clear Ongoing'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bookings', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    const Text('Service workflow for assigned bookings'),
                    const SizedBox(height: 10),
                    clearButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bookings', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        const Text('Service workflow for assigned bookings'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  clearButton,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (_message != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9FBEF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(_message!, style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700)),
            ),
          ],
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w700)),
            ),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumn = constraints.maxWidth >= 880;
              final filter = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _activeTab,
                  isExpanded: true,
                  items: _buildStatusFilterItems(tabCounts),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _activeTab = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Filter by status',
                    prefixIcon: Icon(Icons.filter_list_rounded),
                  ),
                ),
              );

              final search = TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by customer, service, booking ID or status',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              );

              if (!isTwoColumn) {
                return Column(
                  children: [
                    filter,
                    const SizedBox(height: 12),
                    search,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: filter),
                  const SizedBox(width: 12),
                  Expanded(child: search),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (visibleBookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text('No bookings found for current filter.'),
            ),
          ...visibleBookings.map(_bookingCard),
        ],
        ),
      ),
    );
  }
}

class _StatusTab {
  const _StatusTab({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

class _StatusStyle {
  const _StatusStyle({
    required this.bg,
    required this.fg,
    required this.border,
    required this.label,
    required this.icon,
  });

  final Color bg;
  final Color fg;
  final Color border;
  final String label;
  final IconData icon;
}
