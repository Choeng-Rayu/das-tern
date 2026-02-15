import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums_model/medication_type.dart';
import '../../../providers/health_monitoring_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class RecordVitalScreen extends StatefulWidget {
  const RecordVitalScreen({super.key});

  @override
  State<RecordVitalScreen> createState() => _RecordVitalScreenState();
}

class _RecordVitalScreenState extends State<RecordVitalScreen> {
  VitalType? _selectedType;
  final _valueController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _measuredAt = DateTime.now();

  @override
  void dispose() {
    _valueController.dispose();
    _secondaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null) return;
    final value = double.tryParse(_valueController.text);
    if (value == null) return;

    final l10n = AppLocalizations.of(context)!;

    final data = <String, dynamic>{
      'vitalType': _selectedType!.toJson(),
      'value': value,
      'unit': _selectedType!.unit,
      'measuredAt': _measuredAt.toIso8601String(),
      if (_secondaryController.text.isNotEmpty)
        'valueSecondary': double.tryParse(_secondaryController.text),
      if (_notesController.text.isNotEmpty)
        'notes': _notesController.text.trim(),
      'source': 'MANUAL',
    };

    final provider = context.read<HealthMonitoringProvider>();
    final success = await provider.recordVital(data);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vitalRecordedSuccess)),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? l10n.failedToRecordVital)),
        );
      }
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );
    if (time == null) return;

    setState(() {
      _measuredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<HealthMonitoringProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordVital)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectVitalType,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),

            // Vital type grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.1,
              children: VitalType.values.map((type) {
                final selected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = type;
                    _valueController.clear();
                    _secondaryController.clear();
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBlue.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryBlue
                            : AppColors.neutral300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconForType(type),
                          size: 28,
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.neutralGray,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? AppColors.primaryBlue
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          type.unit,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_selectedType != null) ...[
              const SizedBox(height: AppSpacing.lg),

              // Value input
              if (_selectedType == VitalType.bloodPressure) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          labelText: l10n.systolic,
                          hintText: '120',
                          border: const OutlineInputBorder(),
                          suffixText: 'mmHg',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('/', style: TextStyle(fontSize: 24)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _secondaryController,
                        decoration: InputDecoration(
                          labelText: l10n.diastolic,
                          hintText: '80',
                          border: const OutlineInputBorder(),
                          suffixText: 'mmHg',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: _selectedType!.displayName,
                    hintText: l10n.enterValue,
                    border: const OutlineInputBorder(),
                    suffixText: _selectedType!.unit,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),

              // Date/Time picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(
                  '${_measuredAt.day}/${_measuredAt.month}/${_measuredAt.year} '
                  '${_measuredAt.hour.toString().padLeft(2, '0')}:'
                  '${_measuredAt.minute.toString().padLeft(2, '0')}',
                ),
                subtitle: Text(l10n.measuredAt),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Notes
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notesOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.recordVital),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForType(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return Icons.favorite;
      case VitalType.glucose:
        return Icons.water_drop;
      case VitalType.heartRate:
        return Icons.monitor_heart;
      case VitalType.weight:
        return Icons.monitor_weight;
      case VitalType.temperature:
        return Icons.thermostat;
      case VitalType.spo2:
        return Icons.air;
    }
  }
}
