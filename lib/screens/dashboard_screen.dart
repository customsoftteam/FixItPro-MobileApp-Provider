import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../models/provider_profile.dart';
import '../services/dashboard_service.dart';
import '../services/provider_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final ProviderService _providerService = ProviderService();

  DashboardPeriod _selectedPeriod = DashboardPeriod.month;

  late Future<_DashboardViewData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardViewData> _loadDashboard() async {
    final values = await Future.wait<dynamic>([
      _dashboardService.getDashboardData(_selectedPeriod),
      _providerService.getProfile(),
    ]);

    return _DashboardViewData(
      dashboardData: values[0] as DashboardData,
      profile: values[1] as ProviderProfile,
    );
  }

  void _changePeriod(DashboardPeriod nextPeriod) {
    if (_selectedPeriod == nextPeriod) {
      return;
    }

    setState(() {
      _selectedPeriod = nextPeriod;
      _dashboardFuture = _loadDashboard();
    });
  }

  String _formatMoney(double amount) {
    final full = amount.toStringAsFixed(0);
    final withCommas = full.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    return 'Rs $withCommas';
  }

  String _periodLabel(DashboardPeriod period) {
    return switch (period) {
      DashboardPeriod.week => 'This Week',
      DashboardPeriod.month => 'This Month',
      DashboardPeriod.quarter => 'This Quarter',
    };
  }

  Widget _metricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String delta,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(delta, style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _earningsTrendPanel(List<EarningsTrendPoint> trend) {
    if (trend.isEmpty) {
      return const SizedBox(height: 190, child: Center(child: Text('No data available')));
    }

    final maxValue = trend.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const topValueHeight = 18.0;
          const labelHeight = 18.0;
          const jobsHeight = 16.0;
          const verticalSpacing = 16.0;
          const minBarHeight = 24.0;

          final maxBarHeight = (constraints.maxHeight -
                  topValueHeight -
                  labelHeight -
                  jobsHeight -
                  verticalSpacing)
              .clamp(48.0, 150.0)
              .toDouble();

          final itemWidth = trend.length > 5 ? 78.0 : constraints.maxWidth / trend.length;

          return Scrollbar(
            thumbVisibility: trend.length > 5,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.map((point) {
                  final ratio = maxValue <= 0 ? 0.0 : point.value / maxValue;
                  final barHeight =
                      (minBarHeight + (ratio * (maxBarHeight - minBarHeight))).clamp(minBarHeight, maxBarHeight);

                  return SizedBox(
                    width: itemWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: topValueHeight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatMoney(point.value),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF12D3B5), Color(0xFF0F766E)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: labelHeight,
                            child: Text(
                              point.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                          SizedBox(
                            height: jobsHeight,
                            child: Text(
                              '${point.bookings} jobs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bookingStatusPanel(List<BookingStatusEntry> status) {
    final maxCount = status.isEmpty ? 1 : status.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: status.map((item) {
        final ratio = item.value / maxCount;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(Color(item.color)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 34,
                child: Text(
                  '${item.value}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _transactionsStatusChip(String status) {
    final isPaid = status.toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFE6F7EE) : const Color(0xFFFFF4DF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isPaid ? const Color(0xFF198754) : const Color(0xFFAF7A17),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardViewData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load live dashboard data. Please sign in again and make sure the backend is running.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Unable to load dashboard.'));
        }

        final dashboard = snapshot.data!.dashboardData;
        final summary = dashboard.summary;
        final profile = snapshot.data!.profile;

        final metricItems = [
          _MetricItem(
            title: 'Total Bookings',
            value: '${summary.totalBookings}',
            delta: '+12%',
            icon: Icons.calendar_month_outlined,
            iconBg: const Color(0xFFD9F7EE),
            iconColor: const Color(0xFF138B52),
          ),
          _MetricItem(
            title: 'Completed',
            value: '${summary.completedJobs}',
            delta: '+8%',
            icon: Icons.check_circle_outline,
            iconBg: const Color(0xFFE6F6ED),
            iconColor: const Color(0xFF23935A),
          ),
          _MetricItem(
            title: 'Cancelled',
            value: '${summary.cancelledJobs}',
            delta: '-5%',
            icon: Icons.cancel_outlined,
            iconBg: const Color(0xFFFFF2E5),
            iconColor: const Color(0xFFD58C1F),
          ),
          _MetricItem(
            title: 'Total Earnings',
            value: _formatMoney(summary.totalEarnings),
            delta: '+15%',
            icon: Icons.currency_rupee,
            iconBg: const Color(0xFFE8F5F2),
            iconColor: const Color(0xFF13785D),
          ),
          _MetricItem(
            title: "Today's Earnings",
            value: _formatMoney(summary.todayEarnings),
            delta: '${summary.pendingBookings} pending',
            icon: Icons.trending_up,
            iconBg: const Color(0xFFEEF4FF),
            iconColor: const Color(0xFF4576C9),
          ),
        ];

        return LayoutBuilder(
          builder: (context, _pageConstraints) => Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back ${profile.name}. Here is your performance overview.',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dropdown = SizedBox(
                        width: constraints.maxWidth >= 720 ? 240 : double.infinity,
                        child: DropdownButtonFormField<DashboardPeriod>(
                          value: _selectedPeriod,
                          decoration: InputDecoration(
                            labelText: 'Period',
                            prefixIcon: const Icon(Icons.filter_alt_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD7E2EA)),
                            ),
                          ),
                          items: DashboardPeriod.values
                              .map(
                                (period) => DropdownMenuItem<DashboardPeriod>(
                                  value: period,
                                  child: Text(_periodLabel(period)),
                                ),
                              )
                              .toList(),
                          onChanged: (nextPeriod) {
                            if (nextPeriod != null) {
                              _changePeriod(nextPeriod);
                            }
                          },
                        ),
                      );

                      if (constraints.maxWidth >= 720) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: dropdown,
                        );
                      }

                      return dropdown;
                    },
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth >= 1200
                          ? (constraints.maxWidth - 64) / 5
                          : constraints.maxWidth >= 900
                              ? (constraints.maxWidth - 32) / 3
                              : (constraints.maxWidth - 16) / 2;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: metricItems
                            .map(
                              (item) => SizedBox(
                                width: cardWidth,
                                child: _metricCard(
                                  context: context,
                                  title: item.title,
                                  value: item.value,
                                  delta: item.delta,
                                  iconBg: item.iconBg,
                                  iconColor: item.iconColor,
                                  icon: item.icon,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, sectionConstraints) {
                      final isTwoColumn = sectionConstraints.maxWidth >= 980;
                      final panelWidth = isTwoColumn
                          ? (sectionConstraints.maxWidth - 16) / 2
                          : sectionConstraints.maxWidth;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: panelWidth,
                            child: _panel(
                              title: 'Earnings Trend',
                              subtitle: 'Daily earnings - ${_periodLabel(_selectedPeriod)}',
                              child: _earningsTrendPanel(dashboard.earningsTrend),
                            ),
                          ),
                          SizedBox(
                            width: panelWidth,
                            child: _panel(
                              title: 'Booking Status',
                              subtitle: 'Distribution of booking outcomes',
                              child: _bookingStatusPanel(dashboard.bookingStatus),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, sectionConstraints) {
                      final isTwoColumn = sectionConstraints.maxWidth >= 980;
                      final panelWidth = isTwoColumn
                          ? (sectionConstraints.maxWidth - 16) / 2
                          : sectionConstraints.maxWidth;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: panelWidth,
                            child: _panel(
                              title: 'Service Analytics',
                              subtitle: 'Performance by service type',
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Service')),
                                      DataColumn(label: Text('Bookings')),
                                      DataColumn(label: Text('Revenue')),
                                      DataColumn(label: Text('Rating')),
                                    ],
                                    rows: dashboard.serviceAnalytics
                                        .map(
                                          (row) => DataRow(
                                            cells: [
                                              DataCell(Text(row.service)),
                                              DataCell(Text('${row.bookings}')),
                                              DataCell(Text(_formatMoney(row.revenue))),
                                              DataCell(Row(
                                                children: [
                                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF0AD29)),
                                                  const SizedBox(width: 4),
                                                  Text(row.rating.toStringAsFixed(1)),
                                                ],
                                              )),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: panelWidth,
                            child: _panel(
                              title: 'Location Analytics',
                              subtitle: 'Top performing areas',
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Area')),
                                      DataColumn(label: Text('Bookings')),
                                      DataColumn(label: Text('Revenue')),
                                    ],
                                    rows: dashboard.locationAnalytics
                                        .map(
                                          (row) => DataRow(
                                            cells: [
                                              DataCell(Text(row.area)),
                                              DataCell(Text('${row.bookings}')),
                                              DataCell(Text(_formatMoney(row.revenue))),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _panel(
                    title: 'Recent Transactions',
                    subtitle: 'Your latest payment transactions',
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Booking ID')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Method')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: dashboard.transactions
                              .map(
                                (row) => DataRow(
                                  cells: [
                                    DataCell(Text(row.bookingId, style: const TextStyle(fontWeight: FontWeight.w700))),
                                    DataCell(Text(_formatMoney(row.amount))),
                                    DataCell(Text(row.date)),
                                    DataCell(Text(row.method)),
                                    DataCell(_transactionsStatusChip(row.status)),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Response time: ${summary.responseTime} | Provider rating: ${summary.rating.toStringAsFixed(1)}',
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardViewData {
  const _DashboardViewData({
    required this.dashboardData,
    required this.profile,
  });

  final DashboardData dashboardData;
  final ProviderProfile profile;
}

class _MetricItem {
  const _MetricItem({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}
