import 'package:das_tern/core/theme/app_colors.dart';
import 'package:das_tern/core/theme/app_spacing.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_empty_view.dart';
import 'package:das_tern/core/widgets/app_error_view.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/health_vital.dart';
import 'package:das_tern/ui/health/health_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HealthDashboardView extends StatelessWidget {
  const HealthDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Health Vitals',
      body: Consumer<HealthViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const AppLoadingView();
          }

          if (viewModel.errorMessage != null) {
            return AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: () => viewModel.load.execute(),
            );
          }

          if (viewModel.vitals.isEmpty) {
            return const AppEmptyView(
              title: 'No vitals recorded',
              icon: Icons.favorite_outline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: viewModel.vitals.length,
            itemBuilder: (context, index) {
              return _VitalCard(vital: viewModel.vitals[index]);
            },
          );
        },
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({required this.vital});
  final HealthVital vital;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            _vitalIcon(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _vitalLabel(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${vital.displayValue} ${vital.unit}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: vital.isAbnormal
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _timeAgo(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalIcon() {
    final (IconData icon, Color color) = switch (vital.vitalType) {
      VitalType.bloodPressure => (Icons.bloodtype, Colors.red),
      VitalType.heartRate => (Icons.favorite, Colors.pink),
      VitalType.glucose => (Icons.water_drop, Colors.blue),
      VitalType.weight => (Icons.monitor_weight, Colors.teal),
      VitalType.temperature => (Icons.thermostat, Colors.orange),
      VitalType.spo2 => (Icons.air, Colors.indigo),
    };
    return Icon(icon, color: color, size: 32);
  }

  String _vitalLabel() => switch (vital.vitalType) {
    VitalType.bloodPressure => 'Blood Pressure',
    VitalType.heartRate => 'Heart Rate',
    VitalType.glucose => 'Glucose',
    VitalType.weight => 'Weight',
    VitalType.temperature => 'Temperature',
    VitalType.spo2 => 'SpO2',
  };

  String _timeAgo() {
    final diff = DateTime.now().difference(vital.measuredAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
