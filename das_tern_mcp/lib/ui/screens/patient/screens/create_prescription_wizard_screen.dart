import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/dose_provider.dart';
import '../../../../providers/prescription_provider.dart';
import '../../../../utils/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/medicine_form_widget.dart';
import '../../../widgets/language_switcher.dart';

/// Multi-step prescription creation wizard.
/// Step 1: Prescription info (name, doctor, dates)
/// Step 2: Add medicines (repeatable)
/// Step 3: Review & confirm with schedule preview
class CreatePrescriptionWizardScreen extends StatefulWidget {
  const CreatePrescriptionWizardScreen({super.key});

  @override
  State<CreatePrescriptionWizardScreen> createState() =>
      _CreatePrescriptionWizardScreenState();
}

class _CreatePrescriptionWizardScreenState
    extends State<CreatePrescriptionWizardScreen> {
  int _currentStep = 0;
  final _pageController = PageController();

  // Step 1 fields
  final _nameCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  // Step 2 fields
  final List<Map<String, dynamic>> _medicines = [];
  bool _showMedicineForm = false;
  int? _editingIndex;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doctorCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOneMedicine)));
      return;
    }

    final data = <String, dynamic>{
      'title': _nameCtrl.text.isNotEmpty
          ? _nameCtrl.text.trim()
          : l10n.selfPrescribed,
      'startDate': _startDate.toIso8601String().split('T')[0],
      'medicines': _medicines.toList(),
      if (_doctorCtrl.text.isNotEmpty) 'doctorName': _doctorCtrl.text.trim(),
    };

    final success = await context
        .read<PrescriptionProvider>()
        .createPatientPrescription(
          data,
          onAfterCreate: () =>
              context.read<DoseProvider>().fetchTodaySchedule(),
        );

    if (mounted && success) {
      _navigateToSuccess();
    }
  }

  void _navigateToSuccess() {
    Navigator.of(context).pushReplacementNamed(
      AppRouter.prescriptionSuccess,
      arguments: {
        'prescriptionName': _nameCtrl.text.isNotEmpty
            ? _nameCtrl.text.trim()
            : AppLocalizations.of(context)!.selfPrescribed,
        'dateRange': '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
        'doctorName': _doctorCtrl.text.isNotEmpty
            ? _doctorCtrl.text.trim()
            : null,
        'medicines': _medicines.toList(),
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Helper to compute schedule from medicines
  Map<String, List<Map<String, dynamic>>> _computeSchedule() {
    final schedule = <String, List<Map<String, dynamic>>>{};
    for (final med in _medicines) {
      final times = (med['scheduleTimes'] as List?) ?? [];
      bool hasPeriod(String p) =>
          times.any((t) => (t['timePeriod'] as String?) == p);

      if (hasPeriod('MORNING')) {
        schedule.putIfAbsent('morning', () => []).add(med);
      }
      // AFTERNOON and EVENING both map to the daytime preview slot
      if (hasPeriod('AFTERNOON') || hasPeriod('EVENING')) {
        final slot = schedule.putIfAbsent('afternoon', () => []);
        if (!slot.contains(med)) slot.add(med);
      }
      if (hasPeriod('NIGHT')) {
        schedule.putIfAbsent('night', () => []).add(med);
      }
    }
    return schedule;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createPrescription),
        elevation: 0,
        actions: const [LanguageSwitcherButton(lightBackground: true)],
      ),
      body: Column(
        children: [
          // Stepper indicator
          _StepIndicator(
            currentStep: _currentStep,
            steps: [
              l10n.wizardStepPrescription,
              l10n.wizardStepMedicines,
              l10n.wizardStepReview,
            ],
          ),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(l10n),
                _buildStep2(l10n),
                _buildStep3(l10n, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Prescription Info ──
  Widget _buildStep1(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Prescription icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Prescription name
          _WizardTextField(
            controller: _nameCtrl,
            label: l10n.prescriptionName,
            hint: l10n.prescriptionNameHint,
            icon: Icons.medical_services_outlined,
          ),
          const SizedBox(height: AppSpacing.md),

          // Doctor name
          _WizardTextField(
            controller: _doctorCtrl,
            label: l10n.doctorNameOptional,
            hint: l10n.doctorNameHint,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.md),

          // Date pickers
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: l10n.startDate,
                  date: _startDate,
                  formattedDate: _formatDate(_startDate),
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DatePickerField(
                  label: l10n.endDate,
                  date: _endDate,
                  formattedDate: _formatDate(_endDate),
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _goToStep(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.continueButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Add Medicines ──
  Widget _buildStep2(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine count badge
                if (_medicines.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.medicinesCount(_medicines.length),
                      style: const TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Added medicines list
                  ..._medicines.asMap().entries.map(
                    (e) => _MedicineCard(
                      index: e.key,
                      medicine: e.value,
                      onEdit: () {
                        setState(() {
                          _editingIndex = e.key;
                          _showMedicineForm = true;
                        });
                      },
                      onDelete: () {
                        setState(() {
                          _medicines.removeAt(e.key);
                          if (_editingIndex == e.key) {
                            _editingIndex = null;
                            _showMedicineForm = false;
                          }
                        });
                      },
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Empty state
                if (_medicines.isEmpty && !_showMedicineForm) ...[
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            size: 40,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.noMedicinesAdded,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.addYourFirstMedicine,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ],

                // Medicine form
                if (_showMedicineForm) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medication_outlined,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _editingIndex != null
                                  ? l10n.editMedicine
                                  : l10n.addMedicineStep,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(() {
                                _showMedicineForm = false;
                                _editingIndex = null;
                              }),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const Divider(),
                        MedicineFormWidget(
                          initialData: _editingIndex != null
                              ? _medicines[_editingIndex!]
                              : null,
                          onSave: (data) {
                            setState(() {
                              if (_editingIndex != null) {
                                _medicines[_editingIndex!] = data;
                                _editingIndex = null;
                              } else {
                                _medicines.add(data);
                              }
                              _showMedicineForm = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // Add medicine button
                if (!_showMedicineForm) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _showMedicineForm = true;
                        _editingIndex = null;
                      }),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.addAnotherMedicine),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => _goToStep(0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _medicines.isNotEmpty
                        ? () => _goToStep(2)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.reviewPrescription,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Review & Confirm ──
  Widget _buildStep3(AppLocalizations l10n, PrescriptionProvider provider) {
    final schedule = _computeSchedule();
    final durationDays = _endDate.difference(_startDate).inDays;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prescription summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, Color(0xFF1A3BA8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.isNotEmpty
                            ? _nameCtrl.text
                            : l10n.selfPrescribed,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (_doctorCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              color: Colors.white60,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _doctorCtrl.text,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _reviewBadge(
                            '${_medicines.length} ${l10n.medicines}',
                            Icons.medication_outlined,
                          ),
                          const SizedBox(width: 8),
                          _reviewBadge(
                            l10n.prescriptionDuration(durationDays),
                            Icons.calendar_today_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Schedule preview header
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.schedulePreview,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.scheduleAutoGenerated,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Schedule cards
                if (schedule.containsKey('morning'))
                  _ScheduleSlotCard(
                    period: l10n.morning,
                    time: l10n.morningTime,
                    icon: Icons.wb_sunny_rounded,
                    color: const Color(0xFFFFA726),
                    medicines: schedule['morning']!,
                  ),
                if (schedule.containsKey('afternoon'))
                  _ScheduleSlotCard(
                    period: l10n.afternoon,
                    time: l10n.afternoonTime,
                    icon: Icons.wb_twilight,
                    color: const Color(0xFF26C6DA),
                    medicines: schedule['afternoon']!,
                  ),
                if (schedule.containsKey('night'))
                  _ScheduleSlotCard(
                    period: l10n.night,
                    time: l10n.nightTime,
                    icon: Icons.nightlight_round,
                    color: const Color(0xFF7E57C2),
                    medicines: schedule['night']!,
                  ),
              ],
            ),
          ),
        ),

        // Bottom buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => _goToStep(1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _submit,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      l10n.savePrescription,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Step indicator with connected dots
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIdx < currentStep
                    ? AppColors.primaryBlue
                    : AppColors.neutral300,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isActive = stepIdx <= currentStep;
          final isCurrent = stepIdx == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryBlue
                      : AppColors.neutral300,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          width: 3,
                        )
                      : null,
                ),
                child: Center(
                  child: stepIdx < currentStep
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIdx],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Styled text field for wizard
class _WizardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;

  const _WizardTextField({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Date picker field
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final String formattedDate;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Medicine card in the list
class _MedicineCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final AppLocalizations l10n;

  const _MedicineCard({
    required this.index,
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final name = medicine['name'] ?? '';
    final dosage = medicine['dosage'] ?? '';
    final quantity = medicine['quantityPerDose'] ?? '';
    final morning = medicine['morning'] == true;
    final daytime = medicine['daytime'] == true;
    final night = medicine['night'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
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
          // Number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [dosage, quantity].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    if (morning)
                      _timeBadge(l10n.morning, const Color(0xFFFFA726)),
                    if (daytime)
                      _timeBadge(l10n.afternoon, const Color(0xFF26C6DA)),
                    if (night) _timeBadge(l10n.night, const Color(0xFF7E57C2)),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.alertRed,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Schedule time-slot card for preview
class _ScheduleSlotCard extends StatelessWidget {
  final String period;
  final String time;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> medicines;

  const _ScheduleSlotCard({
    required this.period,
    required this.time,
    required this.icon,
    required this.color,
    required this.medicines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          ...medicines.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(m['name'] ?? '', style: const TextStyle(fontSize: 13)),
                  if ((m['dosage'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      m['dosage'],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
