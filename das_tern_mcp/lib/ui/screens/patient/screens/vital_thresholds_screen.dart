import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enums_model/medication_type.dart';
import '../../../../providers/health_monitoring_provider.dart';
import '../../../theme/app_spacing.dart';

class VitalThresholdsScreen extends StatefulWidget {
  const VitalThresholdsScreen({super.key});

  @override
  State<VitalThresholdsScreen> createState() => _VitalThresholdsScreenState();
}

class _VitalThresholdsScreenState extends State<VitalThresholdsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HealthMonitoringProvider>().fetchThresholds();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<HealthMonitoringProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alertThresholds)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: VitalType.values.map((type) {
                final threshold = provider.thresholds
                    .where((t) => t.vitalType == type)
                    .firstOrNull;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(type.displayName),
                    subtitle: Text(
                      threshold != null
                          ? 'Min: ${threshold.minValue ?? '-'} / Max: ${threshold.maxValue ?? '-'}'
                          : l10n.usingDefaults,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editThreshold(context, type, threshold),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _editThreshold(BuildContext context, VitalType type, dynamic threshold) {
    final l10n = AppLocalizations.of(context)!;
    final minCtrl = TextEditingController(
        text: threshold?.minValue?.toString() ?? '');
    final maxCtrl = TextEditingController(
        text: threshold?.maxValue?.toString() ?? '');
    final minSecCtrl = TextEditingController(
        text: threshold?.minSecondary?.toString() ?? '');
    final maxSecCtrl = TextEditingController(
        text: threshold?.maxSecondary?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type.displayName} Thresholds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.minLabel(type.unit),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.maxLabel(type.unit),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (type == VitalType.bloodPressure) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minSecCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.minDiastolic,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: maxSecCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.maxDiastolic,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = <String, dynamic>{
                'vitalType': type.toJson(),
                if (minCtrl.text.isNotEmpty)
                  'minValue': double.parse(minCtrl.text),
                if (maxCtrl.text.isNotEmpty)
                  'maxValue': double.parse(maxCtrl.text),
                if (minSecCtrl.text.isNotEmpty)
                  'minSecondary': double.parse(minSecCtrl.text),
                if (maxSecCtrl.text.isNotEmpty)
                  'maxSecondary': double.parse(maxSecCtrl.text),
              };
              await context
                  .read<HealthMonitoringProvider>()
                  .updateThreshold(data);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
