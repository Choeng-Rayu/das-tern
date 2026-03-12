import 'package:das_tern/core/theme/app_colors.dart';
import 'package:das_tern/core/theme/app_spacing.dart';
import 'package:das_tern/core/widgets/app_card.dart';
import 'package:das_tern/core/widgets/app_empty_view.dart';
import 'package:das_tern/core/widgets/app_error_view.dart';
import 'package:das_tern/core/widgets/app_loading_view.dart';
import 'package:das_tern/core/widgets/app_scaffold.dart';
import 'package:das_tern/data/models/dose_event.dart';
import 'package:das_tern/l10n/app_localizations.dart';
import 'package:das_tern/ui/dose/dose_schedule_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DoseScheduleView extends StatelessWidget {
  const DoseScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.todaySchedule,
      currentIndex: 0,
      body: Consumer<DoseScheduleViewModel>(
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

          if (viewModel.doses.isEmpty) {
            return AppEmptyView(
              title: l10n.noRemindersToday,
              icon: Icons.check_circle_outline,
            );
          }

          return Column(
            children: [
              _ProgressHeader(viewModel: viewModel),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  children: viewModel.groupedDoses.entries.map((entry) {
                    return _PeriodSection(
                      period: entry.key,
                      doses: entry.value,
                      onTaken: viewModel.markTaken,
                      onSkip: viewModel.skipDose,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.viewModel});
  final DoseScheduleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: AppCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${viewModel.takenDoses}/${viewModel.totalDoses}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${(viewModel.progress * 100).toInt()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: viewModel.progress,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({
    required this.period,
    required this.doses,
    required this.onTaken,
    required this.onSkip,
  });

  final String period;
  final List<DoseEvent> doses;
  final Future<void> Function(String) onTaken;
  final Future<void> Function(String, {String? reason}) onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...doses.map(
            (dose) => _DoseCard(
              dose: dose,
              onTaken: () => onTaken(dose.id),
              onSkip: () => onSkip(dose.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.onTaken,
    required this.onSkip,
  });

  final DoseEvent dose;
  final VoidCallback onTaken;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${dose.scheduledTime.hour.toString().padLeft(2, '0')}:${dose.scheduledTime.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            _statusIcon(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.medicationName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${dose.dosage} at $timeStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (dose.isDue) ...[
              IconButton(
                icon: Icon(Icons.check_circle, color: AppColors.success),
                onPressed: onTaken,
                tooltip: 'Mark as taken',
              ),
              IconButton(
                icon: Icon(Icons.cancel_outlined, color: AppColors.warning),
                onPressed: onSkip,
                tooltip: 'Skip',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusIcon() {
    if (dose.isTaken) {
      return Icon(Icons.check_circle, color: AppColors.success, size: 28);
    }
    if (dose.isSkipped) {
      return Icon(Icons.cancel, color: AppColors.warning, size: 28);
    }
    if (dose.isMissed) {
      return Icon(Icons.error, color: AppColors.error, size: 28);
    }
    return Icon(
      Icons.radio_button_unchecked,
      color: AppColors.primary,
      size: 28,
    );
  }
}
