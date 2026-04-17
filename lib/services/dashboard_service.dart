import '../models/dashboard_summary.dart';
import 'api_client.dart';

enum DashboardPeriod { week, month, quarter }

class EarningsTrendPoint {
  const EarningsTrendPoint({
    required this.label,
    required this.value,
    required this.bookings,
  });

  final String label;
  final double value;
  final int bookings;
}

class BookingStatusEntry {
  const BookingStatusEntry({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final int color;
}

class ServiceAnalyticsEntry {
  const ServiceAnalyticsEntry({
    required this.service,
    required this.bookings,
    required this.revenue,
    required this.rating,
  });

  final String service;
  final int bookings;
  final double revenue;
  final double rating;
}

class LocationAnalyticsEntry {
  const LocationAnalyticsEntry({
    required this.area,
    required this.bookings,
    required this.revenue,
  });

  final String area;
  final int bookings;
  final double revenue;
}

class TransactionEntry {
  const TransactionEntry({
    required this.bookingId,
    required this.amount,
    required this.date,
    required this.method,
    required this.status,
  });

  final String bookingId;
  final double amount;
  final String date;
  final String method;
  final String status;
}

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.earningsTrend,
    required this.bookingStatus,
    required this.serviceAnalytics,
    required this.locationAnalytics,
    required this.transactions,
  });

  final DashboardSummary summary;
  final List<EarningsTrendPoint> earningsTrend;
  final List<BookingStatusEntry> bookingStatus;
  final List<ServiceAnalyticsEntry> serviceAnalytics;
  final List<LocationAnalyticsEntry> locationAnalytics;
  final List<TransactionEntry> transactions;
}

class DashboardService {
  Future<DashboardData> getDashboardData(DashboardPeriod period) async {
    final periodKey = switch (period) {
      DashboardPeriod.week => 'week',
      DashboardPeriod.month => 'month',
      DashboardPeriod.quarter => 'quarter',
    };

    final results = await Future.wait<dynamic>([
      ApiClient.instance.get('/providers/earnings/overview'),
      ApiClient.instance.get('/providers/earnings/trend', queryParameters: {'period': periodKey}),
      ApiClient.instance.get('/providers/earnings/by-service'),
      ApiClient.instance.get('/providers/earnings/by-location'),
      ApiClient.instance.get('/providers/earnings/transactions', queryParameters: {'page': 1, 'limit': 10}),
    ]);

    final overview = Map<String, dynamic>.from(results[0] as Map);
    final trendResponse = Map<String, dynamic>.from(results[1] as Map);
    final serviceResponse = Map<String, dynamic>.from(results[2] as Map);
    final locationResponse = Map<String, dynamic>.from(results[3] as Map);
    final transactionResponse = Map<String, dynamic>.from(results[4] as Map);

    final bookingStats = Map<String, dynamic>.from(overview['bookingStats'] as Map? ?? {});
    final earnings = Map<String, dynamic>.from(overview['earnings'] as Map? ?? {});

    final trend = (trendResponse['trend'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => EarningsTrendPoint(
            label: _labelFromDate(period, item['date']?.toString() ?? ''),
            value: (item['earnings'] as num?)?.toDouble() ?? 0,
            bookings: (item['bookings'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();

    final serviceAnalyticsRaw = (serviceResponse['serviceRevenue'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => ServiceAnalyticsEntry(
            service: item['service']?.toString().isNotEmpty == true ? item['service'].toString() : 'Unknown',
            bookings: (item['bookings'] as num?)?.toInt() ?? 0,
            revenue: (item['totalRevenue'] as num?)?.toDouble() ?? 0,
            rating: (item['avgRating'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();

    final locationAnalytics = (locationResponse['locationRevenue'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => LocationAnalyticsEntry(
            area: item['location']?.toString().isNotEmpty == true ? item['location'].toString() : 'Unknown',
            bookings: (item['bookings'] as num?)?.toInt() ?? 0,
            revenue: (item['totalRevenue'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();

    final transactions = (transactionResponse['transactions'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => TransactionEntry(
            bookingId: item['bookingId']?.toString() ?? item['id']?.toString() ?? 'N/A',
            amount: (item['amount'] as num?)?.toDouble() ?? 0,
            date: _formatDate(item['date']?.toString()),
            method: item['method']?.toString() ?? 'N/A',
            status: item['status']?.toString() ?? 'paid',
          ),
        )
        .toList();

    final completed = (bookingStats['completed'] as num?)?.toInt() ?? 0;
    final pending = (bookingStats['pending'] as num?)?.toInt() ?? 0;
    final cancelled = (bookingStats['cancelled'] as num?)?.toInt() ?? 0;
    final rejected = (bookingStats['rejected'] as num?)?.toInt() ?? 0;
    final totalBookings = completed + pending + cancelled + rejected;

    final transactionRatings = (transactionResponse['transactions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => (item['rating'] as num?)?.toDouble())
        .whereType<double>()
        .toList();

    final averageRating = transactionRatings.isEmpty
        ? _weightedRating(serviceAnalyticsRaw)
        : transactionRatings.reduce((sum, value) => sum + value) / transactionRatings.length;

    return DashboardData(
      summary: DashboardSummary(
        totalBookings: totalBookings,
        pendingBookings: pending,
        completedJobs: completed,
        cancelledJobs: cancelled,
        totalEarnings: (earnings['total'] as num?)?.toDouble() ?? 0,
        todayEarnings: (earnings['today'] as num?)?.toDouble() ?? 0,
        rating: averageRating,
        responseTime: 'N/A',
      ),
      earningsTrend: trend,
      bookingStatus: [
        BookingStatusEntry(label: 'Completed', value: completed, color: 0xFF15803D),
        BookingStatusEntry(label: 'Pending', value: pending, color: 0xFFB45309),
        BookingStatusEntry(label: 'Cancelled', value: cancelled, color: 0xFFB91C1C),
        BookingStatusEntry(label: 'Rejected', value: rejected, color: 0xFF64748B),
      ],
      serviceAnalytics: serviceAnalyticsRaw,
      locationAnalytics: locationAnalytics,
      transactions: transactions,
    );
  }

  String _labelFromDate(DashboardPeriod period, String value) {
    final date = DateTime.tryParse(value);
    if (date == null) {
      return value.isEmpty ? 'N/A' : value;
    }

    return switch (period) {
      DashboardPeriod.week => _shortWeekday(date.weekday),
      DashboardPeriod.month => '${date.day}/${date.month}',
      DashboardPeriod.quarter => _shortMonth(date.month),
    };
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'N/A';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _shortWeekday(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  String _shortMonth(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[(month - 1).clamp(0, 11)];
  }

  double _weightedRating(List<ServiceAnalyticsEntry> services) {
    if (services.isEmpty) return 0;
    var totalBookings = 0;
    var totalScore = 0.0;

    for (final service in services) {
      totalBookings += service.bookings;
      totalScore += service.rating * service.bookings;
    }

    if (totalBookings == 0) return 0;
    return totalScore / totalBookings;
  }

}
