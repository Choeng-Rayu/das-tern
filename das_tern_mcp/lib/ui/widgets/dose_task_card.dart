import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dose_event_model/dose_event.dart';
import '../../providers/dose_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'common_widgets.dart';

/// Animated dose task card – shared by home tab and medications period view.
///
/// Shows the medication name, dosage, scheduled time, and an animated
/// checkbox. Tapping the checkbox animates it green and calls
/// [DoseProvider.markTaken]. Tapping the card body opens a detail sheet.
class DoseTaskCard extends StatefulWidget {
  const DoseTaskCard({
    super.key,
    required this.dose,

    /// When true, the checkbox is disabled (used in the Completed section).
    this.readOnly = false,
  });

  final DoseEvent dose;
  final bool readOnly;

  @override
  State<DoseTaskCard> createState() => _DoseTaskCardState();
}

class _DoseTaskCardState extends State<DoseTaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fill;
  bool _calling = false;

  bool get _isTaken =>
      widget.dose.status == 'TAKEN_ON_TIME' ||
      widget.dose.status == 'TAKEN_LATE';
  bool get _isSkipped => widget.dose.status == 'SKIPPED';
  bool get _isDone => _isTaken || _isSkipped;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fill = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (_isDone) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant DoseTaskCard old) {
    super.didUpdateWidget(old);
    if (_isDone && _ctrl.value < 1.0) _ctrl.animateTo(1.0);
    if (!_isDone && !_calling && _ctrl.value > 0.0) _ctrl.animateTo(0.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Toggle the dose: pending → taken, or taken → pending (un-check).
  Future<void> handleCheck() async {
    if (_calling) return;
    setState(() => _calling = true);
    if (_isDone) {
      // Reverse: animate back to unchecked
      await _ctrl.animateTo(0.0);
      if (!mounted) return;
      await context.read<DoseProvider>().markUntaken(widget.dose.id ?? '');
    } else {
      // Forward: animate to checked green
      await _ctrl.animateTo(1.0);
      if (!mounted) return;
      await context.read<DoseProvider>().markTaken(widget.dose.id ?? '');
    }
    if (mounted) setState(() => _calling = false);
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => DoseDetailSheet(
        dose: widget.dose,
        isTaken: _isTaken,
        onMarkTaken: () async {
          Navigator.pop(context);
          await handleCheck();
        },
        onMarkUntaken: _isTaken
            ? () async {
                Navigator.pop(context);
                await handleCheck();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showAsDone = _isDone || _calling;
    final st = widget.dose.scheduledTime;
    final timeStr =
        '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';

    return AnimatedOpacity(
      opacity: showAsDone ? 0.65 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Animated circular checkbox ──
              GestureDetector(
                onTap: handleCheck,
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: _fill,
                  builder: (ctx, _) {
                    final t = _fill.value;
                    final fillColor = _isSkipped
                        ? AppColors.alertRed
                        : AppColors.successGreen;
                    final bg = Color.lerp(Colors.white, fillColor, t)!;
                    final border = Color.lerp(
                      AppColors.primaryBlue,
                      fillColor,
                      t,
                    )!;
                    return Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: border, width: 2),
                      ),
                      child: t > 0.5
                          ? Icon(
                              _isSkipped ? Icons.close : Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Med name + dosage ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dose.medicationName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: showAsDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: showAsDone ? AppColors.textSecondary : null,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.dose.dosage,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Time + status badge ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildBadge(l10n),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(AppLocalizations l10n) {
    if (_calling || _isTaken) {
      return StatusBadge(label: l10n.done, color: AppColors.successGreen);
    }
    if (_isSkipped) {
      return StatusBadge(label: l10n.skipped, color: AppColors.alertRed);
    }
    return StatusBadge(label: l10n.dueToday, color: AppColors.primaryBlue);
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class DoseDetailSheet extends StatelessWidget {
  const DoseDetailSheet({
    super.key,
    required this.dose,
    required this.isTaken,
    required this.onMarkTaken,
    this.onMarkUntaken,
  });

  final DoseEvent dose;
  final bool isTaken;
  final VoidCallback onMarkTaken;

  /// If provided, a "Mark as Pending" button is shown for taken doses.
  final VoidCallback? onMarkUntaken;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final st = dose.scheduledTime;
    final timeStr =
        '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';
    final khmerName = dose.medication?['medicineNameKhmer'] as String?;
    final isDone =
        dose.status == 'TAKEN_ON_TIME' || dose.status == 'TAKEN_LATE';
    final isSkipped = dose.status == 'SKIPPED';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.medicationName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (khmerName != null && khmerName.isNotEmpty)
                        Text(
                          khmerName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (isDone)
                  StatusBadge(label: l10n.done, color: AppColors.successGreen)
                else if (isSkipped)
                  StatusBadge(label: l10n.skipped, color: AppColors.alertRed)
                else
                  StatusBadge(
                    label: l10n.dueToday,
                    color: AppColors.primaryBlue,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(icon: Icons.access_time, label: l10n.time, value: timeStr),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.medication,
              label: l10n.dosage,
              value: dose.dosage.isEmpty ? '-' : dose.dosage,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.wb_sunny_outlined,
              label: l10n.timePeriodLabel,
              value: _periodLabel(dose.timePeriod),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!isDone && !isSkipped)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onMarkTaken,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.markAsTaken),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            if (isDone && onMarkUntaken != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMarkUntaken,
                  icon: const Icon(Icons.undo),
                  label: Text(l10n.markAsPending),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warningOrange,
                    side: const BorderSide(color: AppColors.warningOrange),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'MORNING':
        return 'Morning';
      case 'AFTERNOON':
        return 'Afternoon';
      case 'EVENING':
        return 'Evening';
      case 'NIGHT':
        return 'Night';
      default:
        return period;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
