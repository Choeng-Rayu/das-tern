import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enums_model/medication_type.dart';
import '../../../../models/health_model/health_vital.dart';
import '../../../../providers/health_monitoring_provider.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/app_spacing.dart';

class VitalTrendScreen extends StatefulWidget {
  final VitalType vitalType;
  const VitalTrendScreen({super.key, required this.vitalType});

  @override
  State<VitalTrendScreen> createState() => _VitalTrendScreenState();
}

class _VitalTrendScreenState extends State<VitalTrendScreen> {
  String _period = '7';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    final days = int.parse(_period);
    final start = now.subtract(Duration(days: days));

    context.read<HealthMonitoringProvider>().fetchVitals(
      vitalType: widget.vitalType.toJson(),
      startDate: start.toIso8601String(),
      endDate: now.toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<HealthMonitoringProvider>();
    final vitals =
        provider.vitals.where((v) => v.vitalType == widget.vitalType).toList()
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.vitalType.displayName} Trends')),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: ['7', '30', '90'].map((d) {
                final selected = _period == d;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.daysCount(d)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _period = d);
                      _loadData();
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Chart
          if (provider.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (vitals.isEmpty)
            Expanded(child: Center(child: Text(l10n.noDataAvailable)))
          else ...[
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= vitals.length) {
                              return const SizedBox.shrink();
                            }
                            final d = vitals[idx].measuredAt;
                            return Text(
                              '${d.day}/${d.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                          interval: (vitals.length / 5).ceilToDouble().clamp(
                            1,
                            double.infinity,
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: vitals
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                            .toList(),
                        isCurved: true,
                        color: AppColors.primaryBlue,
                        barWidth: 2,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        ),
                      ),
                      if (widget.vitalType == VitalType.bloodPressure)
                        LineChartBarData(
                          spots: vitals
                              .asMap()
                              .entries
                              .where((e) => e.value.valueSecondary != null)
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.valueSecondary!,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: AppColors.warningOrange,
                          barWidth: 2,
                          dotData: const FlDotData(show: true),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // History list
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: vitals.length,
                itemBuilder: (context, index) {
                  final vital = vitals[vitals.length - 1 - index];
                  return _VitalHistoryItem(vital: vital);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalHistoryItem extends StatelessWidget {
  final HealthVital vital;
  const _VitalHistoryItem({required this.vital});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: vital.isAbnormal
                ? AppColors.alertRed
                : AppColors.successGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          '${vital.displayValue} ${vital.unit}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${vital.measuredAt.day}/${vital.measuredAt.month}/${vital.measuredAt.year} '
          '${vital.measuredAt.hour.toString().padLeft(2, '0')}:'
          '${vital.measuredAt.minute.toString().padLeft(2, '0')}',
        ),
        trailing: vital.isAbnormal
            ? const Icon(Icons.warning, color: AppColors.alertRed, size: 20)
            : null,
      ),
    );
  }
}
