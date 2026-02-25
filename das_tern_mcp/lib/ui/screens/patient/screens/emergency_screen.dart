import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/health_monitoring_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _messageController = TextEditingController();
  bool _triggered = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _triggerEmergency() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<HealthMonitoringProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmEmergency),
        content: Text(l10n.confirmEmergencyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await provider.triggerEmergency({
      'message': _messageController.text.isNotEmpty
          ? _messageController.text.trim()
          : l10n.emergencyAlertTriggered,
    });

    if (mounted && success) {
      setState(() => _triggered = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<HealthMonitoringProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencyLabel),
        backgroundColor: AppColors.alertRed,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _triggered
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.emergencyAlertSent,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.caregiversNotified,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.done),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: AppColors.alertRed,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.emergencyAlert,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.emergencyAlertDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: l10n.messageOptional,
                        hintText: l10n.describeSituation,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _triggerEmergency,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alertRed,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 8,
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.emergency, size: 48),
                                  SizedBox(height: 8),
                                  Text(
                                    'SOS',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
