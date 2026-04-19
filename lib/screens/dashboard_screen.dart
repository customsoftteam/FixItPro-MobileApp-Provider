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

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
    await _dashboardFuture;
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

  String _percentLabel(int value, int total) {
    if (total <= 0) return '0%';
    final percent = (value * 100) / total;
    return '${percent.toStringAsFixed(1)}%';
  }

  String _doubleLabel(double value) {
    if (value.isNaN || value.isInfinite) return '0.0';
    return value.toStringAsFixed(1);
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'SP';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  Widget _emptyState({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _analyticsStat({
    required String label,
    required String value,
    Color accent = const Color(0xFF0F766E),
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: accent),
          ),
        ],
      ),
    );
  }

  int _gridColumns({
    required double width,
    required int maxColumns,
  }) {
    if (width < 560) return 1;
    if (width < 900) return maxColumns >= 2 ? 2 : 1;
    if (width < 1240) return maxColumns >= 3 ? 3 : maxColumns;
    if (width < 1520) return maxColumns >= 4 ? 4 : maxColumns;
    return maxColumns;
  }

  double _gridItemWidth({
    required double width,
    required int columns,
    required double spacing,
  }) {
    final totalSpacing = spacing * (columns - 1);
    return (width - totalSpacing) / columns;
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String insight,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Text(
              insight,
              style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
    IconData? icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF0F8F7B)),
                ),
                const SizedBox(width: 10),
              ],
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

        final totalBookings = summary.totalBookings;
        final completionRate = _percentLabel(summary.completedJobs, totalBookings);
        final cancellationRate = _percentLabel(summary.cancelledJobs, totalBookings);
        final rejectedCount = dashboard.bookingStatus
          .where((entry) => entry.label.toLowerCase() == 'rejected')
          .fold<int>(0, (sum, entry) => sum + entry.value);
        final rejectedRate = _percentLabel(rejectedCount, totalBookings);
        final avgTicket = summary.completedJobs <= 0 ? 0.0 : summary.totalEarnings / summary.completedJobs;

        final topService = dashboard.serviceAnalytics.isEmpty
            ? null
            : (List<ServiceAnalyticsEntry>.from(dashboard.serviceAnalytics)
                  ..sort((a, b) => b.revenue.compareTo(a.revenue)))
                .first;

        final topArea = dashboard.locationAnalytics.isEmpty
            ? null
            : (List<LocationAnalyticsEntry>.from(dashboard.locationAnalytics)
                  ..sort((a, b) => b.revenue.compareTo(a.revenue)))
                .first;

        final metricItems = [
          _MetricItem(
            title: 'Total Bookings',
            value: '${summary.totalBookings}',
            insight: '${summary.pendingBookings} pending',
            icon: Icons.calendar_month_outlined,
            iconBg: const Color(0xFFD9F7EE),
            iconColor: const Color(0xFF138B52),
          ),
          _MetricItem(
            title: 'Completed',
            value: '${summary.completedJobs}',
            insight: '$completionRate completion rate',
            icon: Icons.check_circle_outline,
            iconBg: const Color(0xFFE6F6ED),
            iconColor: const Color(0xFF23935A),
          ),
          _MetricItem(
            title: 'Rejected Bookings',
            value: '$rejectedCount',
            insight: '$rejectedRate rejection rate',
            icon: Icons.block_outlined,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFB91C1C),
          ),
          _MetricItem(
            title: 'Total Earnings',
            value: _formatMoney(summary.totalEarnings),
            insight: '${_formatMoney(summary.todayEarnings)} today',
            icon: Icons.currency_rupee,
            iconBg: const Color(0xFFE8F5F2),
            iconColor: const Color(0xFF13785D),
          ),
        ];

        return LayoutBuilder(
          builder: (context, _pageConstraints) => RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: Scrollbar(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF153145), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 760;

                        final left = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Performance Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Welcome back ${profile.name}. Here is your live business overview.',
                              style: const TextStyle(color: Color(0xFFD1FAF5), fontSize: 14.5),
                            ),
                          ],
                        );

                        final right = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x44FFFFFF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF12B5A4),
                                child: Text(
                                  _initials(profile.name),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _periodLabel(_selectedPeriod),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Rating ${summary.rating.toStringAsFixed(1)}',
                                    style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              left,
                              const SizedBox(height: 14),
                              right,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 12),
                            right,
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dropdown = ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth >= 720 ? 220 : constraints.maxWidth,
                          maxWidth: constraints.maxWidth >= 720 ? 280 : constraints.maxWidth,
                        ),
                        child: DropdownButtonFormField<DashboardPeriod>(
                          value: _selectedPeriod,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Dashboard Period',
                            prefixIcon: const Icon(Icons.filter_alt_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      const spacing = 16.0;
                      final columns = _gridColumns(width: constraints.maxWidth, maxColumns: 4);
                      final cardWidth = _gridItemWidth(
                        width: constraints.maxWidth,
                        columns: columns,
                        spacing: spacing,
                      );

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: metricItems
                            .map(
                              (item) => SizedBox(
                                width: cardWidth,
                                child: _metricCard(
                                  title: item.title,
                                  value: item.value,
                                  insight: item.insight,
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
                      const spacing = 16.0;
                      final columns = _gridColumns(width: sectionConstraints.maxWidth, maxColumns: 2);
                      final panelWidth = _gridItemWidth(
                        width: sectionConstraints.maxWidth,
                        columns: columns,
                        spacing: spacing,
                      );

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: panelWidth,
                            child: _panel(
                              title: 'Service Analytics',
                              subtitle: 'Performance by service type',
                              icon: Icons.handyman_outlined,
                              child: LayoutBuilder(
                                builder: (context, tableConstraints) {
                                  if (dashboard.serviceAnalytics.isEmpty) {
                                    return _emptyState(message: 'No service analytics available for the selected period.');
                                  }

                                  return Scrollbar(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: tableConstraints.maxWidth,
                                        ),
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
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: panelWidth,
                            child: _panel(
                              title: 'Location Analytics',
                              subtitle: 'Top performing areas',
                              icon: Icons.location_on_outlined,
                              child: LayoutBuilder(
                                builder: (context, tableConstraints) {
                                  if (dashboard.locationAnalytics.isEmpty) {
                                    return _emptyState(message: 'No location analytics available for the selected period.');
                                  }

                                  return Scrollbar(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: tableConstraints.maxWidth,
                                        ),
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
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _panel(
                    title: 'Live Analytics Snapshot',
                    subtitle: 'Real-time insights from your current backend data',
                    icon: Icons.auto_graph_outlined,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 10.0;
                        final columns = constraints.maxWidth >= 980
                            ? 4
                            : constraints.maxWidth >= 620
                                ? 2
                                : 1;
                        final itemWidth = _gridItemWidth(
                          width: constraints.maxWidth,
                          columns: columns,
                          spacing: spacing,
                        );

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _analyticsStat(label: 'Completion Rate', value: completionRate),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _analyticsStat(label: 'Cancellation Rate', value: cancellationRate),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _analyticsStat(
                                label: 'Avg Ticket Value',
                                value: _formatMoney(avgTicket),
                                accent: const Color(0xFF1D4ED8),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _analyticsStat(
                                label: 'Provider Rating',
                                value: _doubleLabel(summary.rating),
                                accent: const Color(0xFFB45309),
                              ),
                            ),
                            if (topService != null)
                              SizedBox(
                                width: itemWidth,
                                child: _analyticsStat(
                                  label: 'Top Service',
                                  value: '${topService.service} (${_formatMoney(topService.revenue)})',
                                  accent: const Color(0xFF0F766E),
                                ),
                              ),
                            if (topArea != null)
                              SizedBox(
                                width: itemWidth,
                                child: _analyticsStat(
                                  label: 'Top Area',
                                  value: '${topArea.area} (${_formatMoney(topArea.revenue)})',
                                  accent: const Color(0xFF7C3AED),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _panel(
                    title: 'Recent Transactions',
                    subtitle: 'Your latest payment transactions',
                    icon: Icons.receipt_long_outlined,
                    child: LayoutBuilder(
                      builder: (context, tableConstraints) {
                        if (dashboard.transactions.isEmpty) {
                          return _emptyState(message: 'No recent transactions available.');
                        }

                        return Scrollbar(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: tableConstraints.maxWidth,
                              ),
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
                        );
                      },
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
    required this.insight,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String insight;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}
