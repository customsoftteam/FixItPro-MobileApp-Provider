import 'package:flutter/material.dart';

import '../models/booking_item.dart';

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  final BookingItem booking;

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} • $hour:$minute';
  }

  String _formatCurrency(double value) {
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'pending' => 'Pending Approval',
      'assigned' => 'Assigned',
      'accepted' => 'Accepted',
      'in_progress' => 'In Progress',
      'paused' => 'Paused',
      'otp_sent' => 'OTP Sent',
      'completed' => 'Completed',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      _ => normalized.replaceAll('_', ' ').split(' ').map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        }).join(' '),
    };
  }

  String _formatServiceDuration() {
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

  Widget _detailsField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = booking.status.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pagePadding = constraints.maxWidth >= 1000
                ? 24.0
                : constraints.maxWidth >= 700
                    ? 16.0
                    : 12.0;
            final twoCol = constraints.maxWidth >= 840;

            return ListView(
              padding: EdgeInsets.fromLTRB(pagePadding, 10, pagePadding, 18),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        booking.id,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Customer Details',
                  child: twoCol
                      ? Row(
                          children: [
                            Expanded(child: _detailsField(label: 'Name', value: booking.customerName)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _detailsField(
                                label: 'Mobile',
                                value: booking.customerMobile.isEmpty ? 'Not available' : booking.customerMobile,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailsField(label: 'Name', value: booking.customerName),
                            const SizedBox(height: 10),
                            _detailsField(
                              label: 'Mobile',
                              value: booking.customerMobile.isEmpty ? 'Not available' : booking.customerMobile,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Service Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailsField(label: 'Service', value: booking.serviceName),
                      const SizedBox(height: 10),
                      _detailsField(label: 'Schedule', value: _formatDateTime(booking.scheduledAt)),
                      const SizedBox(height: 10),
                      _detailsField(label: 'Address', value: booking.address),
                      const SizedBox(height: 10),
                      _detailsField(label: 'Notes', value: booking.notes.isEmpty ? 'No notes provided' : booking.notes),
                      const SizedBox(height: 10),
                      _detailsField(label: 'Current Status', value: _statusLabel(status)),
                      const SizedBox(height: 10),
                      _detailsField(label: 'Timer', value: _formatServiceDuration()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Pricing and Payment',
                  child: twoCol
                      ? Row(
                          children: [
                            Expanded(child: _detailsField(label: 'Amount', value: _formatCurrency(booking.amount))),
                            const SizedBox(width: 16),
                            Expanded(child: _detailsField(label: 'Payment Method', value: booking.paymentMethod)),
                            const SizedBox(width: 16),
                            Expanded(child: _detailsField(label: 'Payment Status', value: booking.paymentStatus)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailsField(label: 'Amount', value: _formatCurrency(booking.amount)),
                            const SizedBox(height: 10),
                            _detailsField(label: 'Payment Method', value: booking.paymentMethod),
                            const SizedBox(height: 10),
                            _detailsField(label: 'Payment Status', value: booking.paymentStatus),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Timeline',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailsField(
                        label: 'Created',
                        value: booking.createdAt == null ? 'Not available' : _formatDateTime(booking.createdAt!),
                      ),
                      const SizedBox(height: 10),
                      _detailsField(
                        label: 'Service Start',
                        value: booking.serviceStartTime == null ? 'Not available' : _formatDateTime(booking.serviceStartTime!),
                      ),
                      const SizedBox(height: 10),
                      _detailsField(
                        label: 'Service End',
                        value: booking.serviceEndTime == null ? 'Not available' : _formatDateTime(booking.serviceEndTime!),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
