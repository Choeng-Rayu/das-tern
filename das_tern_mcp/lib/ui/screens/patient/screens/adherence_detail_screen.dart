import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/adherence_chart.dart';
import '../../../../providers/adherence_provider.dart';
import '../../../../models/adherence_model/adherence_result.dart';

class AdherenceDetailScreen extends StatefulWidget {
  const AdherenceDetailScreen({super.key});

  @override
  State<AdherenceDetailScreen> createState() => _AdherenceDetailScreenState();
}

class _AdherenceDetailScreenState extends State<AdherenceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdherenceProvider>().fetchAll();
      context.read<AdherenceProvider>().fetchTrends(days: 30);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adherence'),
      ),
      body: Consumer<AdherenceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.todayAdherence == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Build trend data
          final trendsRaw = provider.trends?['daily'] as List? ?? [];
          final trendData = trendsRaw
              .map((d) => AdherenceTrendData.fromJson(Map<String, dynamic>.from(d)))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchAll();
              await provider.fetchTrends(days: 30);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                const SizedBox(height: AppSpacing.md),
                // Chart
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '30-Day Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AdherenceChart(data: trendData),
                const SizedBox(height: AppSpacing.lg),

                // Period tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryBlue,
                  tabs: const [
                    Tab(text: 'Today'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
                SizedBox(
                  height: 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPeriodView(
                        provider.todayAdherence,
                        'daily',
                      ),
                      _buildPeriodView(
                        provider.weeklyAdherence,
                        'weekly',
                      ),
                      _buildPeriodView(
                        provider.monthlyAdherence,
                        'monthly',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodView(Map<String, dynamic>? data, String period) {
    if (data == null) {
      return const Center(child: Text('No data', style: TextStyle(color: AppColors.textSecondary)));
    }

    final pct = (data['percentage'] as num?)?.toDouble() ?? 0.0;
    final taken = data['taken'] as int? ?? data['takenCount'] as int? ?? 0;
    final total = data['total'] as int? ?? data['totalCount'] as int? ?? 0;
    final colorCode = data['colorCode'] as String? ?? 'GREEN';
    final color = AdherenceProvider.getAdherenceColor(colorCode);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            '${pct.round()}%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$taken of $total doses taken',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              pct >= 90
                  ? 'Excellent'
                  : pct >= 70
                      ? 'Needs Improvement'
                      : 'Low Adherence',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
