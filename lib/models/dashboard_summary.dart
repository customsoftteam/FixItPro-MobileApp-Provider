class DashboardSummary {
  const DashboardSummary({
    required this.totalBookings,
    required this.pendingBookings,
    required this.completedJobs,
    required this.cancelledJobs,
    required this.totalEarnings,
    required this.todayEarnings,
    required this.rating,
    required this.responseTime,
  });

  final int totalBookings;
  final int pendingBookings;
  final int completedJobs;
  final int cancelledJobs;
  final double totalEarnings;
  final double todayEarnings;
  final double rating;
  final String responseTime;
}
