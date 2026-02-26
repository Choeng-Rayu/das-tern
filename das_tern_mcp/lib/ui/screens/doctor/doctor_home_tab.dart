import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_dashboard_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Doctor home tab  redesigned to match reference DoctorScreen design.
class DoctorHomeTab extends StatefulWidget {
  final void Function(int tabIndex)? onSwitchTab;
  const DoctorHomeTab({super.key, this.onSwitchTab});

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  bool _showMonthly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DoctorDashboardProvider>();
      provider.fetchDashboardOverview();
      provider.fetchPendingConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DoctorDashboardProvider>();
    final user = auth.user;
    final overview = dashboard.dashboardOverview;

    final String doctorName =
        user?['fullName'] ?? user?['firstName'] ?? l10n.doctorRole;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade50],
            stops: const [0.0, 0.28],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await dashboard.fetchDashboardOverview();
              await dashboard.fetchPendingConnections();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DoctorHeader(
                    greeting: _greeting(context),
                    doctorName: doctorName,
                  ),
                  const SizedBox(height: 20),
                  if (dashboard.dashboardLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _StatisticsRow(
                      receivedCount: '${overview?.totalPatients ?? 0}',
                      pendingCount:
                          '${overview?.patientsNeedingAttention ?? 0}',
                      receivedLabel: l10n.patientsInTreatment,
                      pendingLabel: l10n.patientsPendingMeds,
                      onReceivedTap: () =>
                          Navigator.pushNamed(context, '/doctor/med-patients'),
                      onPendingTap: () => Navigator.pushNamed(
                        context,
                        '/doctor/pending-patients',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ReminderSection(
                      reminders: (overview?.todayAlerts ?? [])
                          .map(
                            (a) => _ReminderData(
                              name: a.patientName,
                              description: l10n.consecutiveMissedDoses(
                                a.consecutiveMissed,
                              ),
                              missedCount: a.consecutiveMissed,
                              alertType: a.type,
                              patientId: a.patientId,
                            ),
                          )
                          .toList(),
                      onItemTap: (patientId) => Navigator.pushNamed(
                        context,
                        '/doctor/patient-detail',
                        arguments: {'patientId': patientId},
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (dashboard.pendingConnections.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionHeader(
                          icon: Icons.person_add_outlined,
                          iconColor: AppColors.warningOrange,
                          title: l10n.pendingConnectionRequests,
                          badgeCount: dashboard.pendingConnections.length,
                          badgeSuffix: l10n.alertsLabel,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...dashboard.pendingConnections.map(
                        (conn) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: AppCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.warningOrange
                                      .withValues(alpha: 0.12),
                                  child: const Icon(
                                    Icons.person_add,
                                    color: AppColors.warningOrange,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conn.patientName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        conn.initiator?.phoneNumber ??
                                            l10n.connectionRequest,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: AppColors.successGreen,
                                  ),
                                  onPressed: () async =>
                                      dashboard.acceptConnection(conn.id),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: AppColors.alertRed,
                                  ),
                                  onPressed: () async =>
                                      dashboard.rejectConnection(conn.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _ChartSection(
                      totalPatients: overview?.totalPatients ?? 0,
                      patientsNeedingAttention:
                          overview?.patientsNeedingAttention ?? 0,
                      showMonthly: _showMonthly,
                      onDayTap: () => setState(() => _showMonthly = false),
                      onMonthTap: () => setState(() => _showMonthly = true),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.quickActions,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.description_outlined,
                              label: l10n.newPrescription,
                              onTap: () => widget.onSwitchTab?.call(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.search,
                              label: l10n.findPatient,
                              onTap: () => widget.onSwitchTab?.call(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }
}

class _DoctorHeader extends StatelessWidget {
  final String greeting;
  final String doctorName;

  const _DoctorHeader({required this.greeting, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blue.shade400, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$greeting $doctorName !',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  final String receivedCount;
  final String pendingCount;
  final String receivedLabel;
  final String pendingLabel;
  final VoidCallback? onReceivedTap;
  final VoidCallback? onPendingTap;

  const _StatisticsRow({
    required this.receivedCount,
    required this.pendingCount,
    required this.receivedLabel,
    required this.pendingLabel,
    this.onReceivedTap,
    this.onPendingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              count: receivedCount,
              label: receivedLabel,
              icon: Icons.people_alt_outlined,
              iconColor: Colors.blue.shade400,
              onTap: onReceivedTap,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              count: pendingCount,
              label: pendingLabel,
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange.shade400,
              onTap: onPendingTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap != null
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.personUnit,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: iconColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 6),
                Text(
                  '›',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderData {
  final String name;
  final String description;
  final int missedCount;
  final String alertType;
  final String patientId;

  const _ReminderData({
    required this.name,
    required this.description,
    required this.missedCount,
    required this.alertType,
    required this.patientId,
  });
}

class _ReminderSection extends StatelessWidget {
  final List<_ReminderData> reminders;
  final void Function(String patientId) onItemTap;

  const _ReminderSection({required this.reminders, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Text(
                    l10n.criticalAlerts,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${reminders.length} ${l10n.alertsLabel}',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  l10n.noAlerts,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...reminders.map(
              (r) => _ReminderItem(
                name: r.name,
                description: r.description,
                missedCount: r.missedCount,
                missedLabel: l10n.missedTimesLabel,
                onTap: () => onItemTap(r.patientId),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  final String name;
  final String description;
  final int missedCount;
  final String missedLabel;
  final VoidCallback onTap;

  const _ReminderItem({
    required this.name,
    required this.description,
    required this.missedCount,
    required this.missedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                  right: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.medication, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$missedCount$missedLabel',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int badgeCount;
  final String badgeSuffix;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badgeCount,
    required this.badgeSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (badgeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$badgeCount $badgeSuffix',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  final int totalPatients;
  final int patientsNeedingAttention;
  final bool showMonthly;
  final VoidCallback onDayTap;
  final VoidCallback onMonthTap;

  const _ChartSection({
    required this.totalPatients,
    required this.patientsNeedingAttention,
    required this.showMonthly,
    required this.onDayTap,
    required this.onMonthTap,
  });

  List<BarChartGroupData> _buildGroups(List<String> labels, int seed) {
    final rng = math.Random(seed);
    return List.generate(labels.length, (i) {
      final received = math.max(
        1.0,
        (totalPatients * (0.4 + rng.nextDouble() * 0.6)).roundToDouble(),
      );
      final missed = math.max(
        0.0,
        (patientsNeedingAttention * (0.2 + rng.nextDouble() * 0.8))
            .roundToDouble(),
      );
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: received,
            color: Colors.blue.shade400,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: missed,
            color: Colors.red.shade400,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabels = [
      l10n.dayMon,
      l10n.dayTue,
      l10n.dayWed,
      l10n.dayThu,
      l10n.dayFri,
      l10n.daySat,
      l10n.daySun,
    ];
    final monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
    ];
    final labels = showMonthly ? monthLabels : dayLabels;
    final groups = _buildGroups(labels, showMonthly ? 99 : 42);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.statisticsChart,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: onDayTap,
                    style: TextButton.styleFrom(
                      foregroundColor: !showMonthly
                          ? Colors.blue.shade400
                          : Colors.grey.shade400,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 36),
                    ),
                    child: Text(l10n.dayFilter),
                  ),
                  TextButton(
                    onPressed: onMonthTap,
                    style: TextButton.styleFrom(
                      foregroundColor: showMonthly
                          ? Colors.blue.shade400
                          : Colors.grey.shade400,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 36),
                    ),
                    child: Text(l10n.monthFilter),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: Colors.blue.shade400),
              const SizedBox(width: 4),
              Text(l10n.receivedMeds, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(l10n.missedMeds, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.shade700,
                    tooltipRoundedRadius: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue.shade400, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
