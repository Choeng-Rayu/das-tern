import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums_model/medication_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Medicine form with grouped card sections and a clean, modern design.
///
/// Fixes from previous version:
///  - `DropdownButtonFormField.initialValue` → `value` (correct API)
///  - Removed duplicate `_ScheduleChip` definition
///  - Flat field list → grouped into labeled card sections
class MedicineFormWidget extends StatefulWidget {
  const MedicineFormWidget({
    super.key,
    required this.onSave,
    this.initialData,
    this.showSaveButton = true,
  });

  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;
  final bool showSaveButton;

  @override
  State<MedicineFormWidget> createState() => _MedicineFormWidgetState();
}

class _MedicineFormWidgetState extends State<MedicineFormWidget> {
  // ── Controllers ───────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameKhmerController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────

  MedicineType _medicineType = MedicineType.oral;
  MedicineUnit _unit = MedicineUnit.tablet;
  bool _morning = true;
  bool _afternoon = false;
  bool _evening = false;
  bool _night = false;
  bool _beforeMeal = false;
  bool _isPRN = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameController.text = d['medicineName'] ?? '';
      _nameKhmerController.text = d['medicineNameKhmer'] ?? '';
      _dosageController.text = (d['dosageAmount'] ?? '').toString();
      _frequencyController.text = d['frequency'] ?? '';
      _durationController.text = (d['durationDays'] ?? '').toString();
      _descriptionController.text = d['description'] ?? '';
      _noteController.text = d['additionalNote'] ?? '';
      _medicineType = d['medicineType'] != null
          ? MedicineType.fromJson(d['medicineType'])
          : MedicineType.oral;
      _unit = d['unit'] != null
          ? MedicineUnit.fromJson(d['unit'])
          : MedicineUnit.tablet;
      _morning = d['morningDosage'] != null ? true : (d['morning'] ?? true);
      _afternoon = d['afternoonDosage'] != null ? true : (d['afternoon'] ?? false);
      _evening = d['eveningDosage'] != null ? true : (d['evening'] ?? false);
      _night = d['nightDosage'] != null ? true : (d['night'] ?? false);
      _beforeMeal = d['beforeMeal'] ?? false;
      _isPRN = d['isPRN'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameKhmerController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final unitStr = _unit.toJson().toLowerCase();
    final scheduleTimes = <Map<String, String>>[
      if (_morning) {'timePeriod': 'morning', 'time': '07:00'},
      if (_afternoon) {'timePeriod': 'afternoon', 'time': '12:00'},
      if (_evening) {'timePeriod': 'evening', 'time': '17:00'},
      if (_night) {'timePeriod': 'night', 'time': '20:00'},
    ];

    widget.onSave({
      'medicineName': _nameController.text.trim(),
      'medicineNameKhmer': _nameKhmerController.text.trim(),
      'medicineType': _medicineType.toJson(),
      'unit': _unit.toJson(),
      'dosageAmount': double.tryParse(_dosageController.text) ?? 1,
      'frequency': _frequencyController.text.trim(),
      'durationDays': int.tryParse(_durationController.text) ?? 30,
      if (_morning)
        'morningDosage': {
          'amount': (_dosageController.text.trim().isEmpty
              ? '1'
              : _dosageController.text.trim()),
          'beforeMeal': _beforeMeal,
        },
      if (_afternoon)
        'afternoonDosage': {
          'amount': (_dosageController.text.trim().isEmpty
              ? '1'
              : _dosageController.text.trim()),
          'beforeMeal': _beforeMeal,
        },
      if (_evening)
        'eveningDosage': {
          'amount': (_dosageController.text.trim().isEmpty
              ? '1'
              : _dosageController.text.trim()),
          'beforeMeal': _beforeMeal,
        },
      if (_night)
        'nightDosage': {
          'amount': (_dosageController.text.trim().isEmpty
              ? '1'
              : _dosageController.text.trim()),
          'beforeMeal': _beforeMeal,
        },
      'beforeMeal': _beforeMeal,
      'isPRN': _isPRN,
      if (_descriptionController.text.isNotEmpty)
        'description': _descriptionController.text.trim(),
      if (_noteController.text.isNotEmpty)
        'additionalNote': _noteController.text.trim(),
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: Basic Info ──────────────────────────────────
          _FormSection(
            icon: Icons.medication_outlined,
            title: 'Medicine Info',
            children: [
              _field(
                controller: _nameController,
                label: l10n.medicineNameRequired,
                hint: l10n.medicineNameHintExample,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.required : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                controller: _nameKhmerController,
                label: l10n.medicineNameKhmer,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _dropdown<MedicineType>(
                      label: l10n.typeLabel,
                      value: _medicineType,
                      items: MedicineType.values,
                      displayName: (t) => t.displayName,
                      onChanged: (v) => setState(() => _medicineType = v!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _dropdown<MedicineUnit>(
                      label: l10n.unit,
                      value: _unit,
                      items: MedicineUnit.values,
                      displayName: (u) => u.displayName,
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Section 2: Dosage & Duration ──────────────────────────
          _FormSection(
            icon: Icons.schedule_outlined,
            title: 'Dosage & Duration',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _dosageController,
                      label: l10n.dosageAmount,
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _field(
                      controller: _frequencyController,
                      label: l10n.frequencyRequired,
                      hint: l10n.frequencyHintExample,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.required
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                controller: _durationController,
                label: l10n.durationDaysLabel,
                hint: '30',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Section 3: Schedule ───────────────────────────────────
          _FormSection(
            icon: Icons.wb_sunny_outlined,
            title: l10n.schedule,
            children: [
              // Time-of-day chips
              Row(
                children: [
                  _ScheduleChip(
                    label: l10n.morning,
                    icon: Icons.wb_sunny_rounded,
                    selected: _morning,
                    onTap: () => setState(() => _morning = !_morning),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ScheduleChip(
                    label: l10n.afternoon,
                    icon: Icons.wb_twilight,
                    color: const Color(0xFF26C6DA),
                    selected: _afternoon,
                    onTap: () => setState(() => _afternoon = !_afternoon),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _ScheduleChip(
                    label: l10n.evening,
                    icon: Icons.wb_twilight,
                    color: const Color(0xFFFF7043),
                    selected: _evening,
                    onTap: () => setState(() => _evening = !_evening),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ScheduleChip(
                    label: l10n.night,
                    icon: Icons.nightlight_round,
                    selected: _night,
                    onTap: () => setState(() => _night = !_night),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Before meal & PRN toggles
              _ToggleRow(
                icon: Icons.restaurant_outlined,
                label: l10n.beforeMeal,
                value: _beforeMeal,
                onChanged: (v) => setState(() => _beforeMeal = v),
              ),
              const Divider(height: 1),
              _ToggleRow(
                icon: Icons.access_time_outlined,
                label: l10n.prn,
                value: _isPRN,
                onChanged: (v) => setState(() => _isPRN = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Section 4: Notes ──────────────────────────────────────
          _FormSection(
            icon: Icons.notes_outlined,
            title: 'Notes',
            children: [
              _field(
                controller: _descriptionController,
                label: l10n.descriptionLabel,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                controller: _noteController,
                label: l10n.additionalNote,
                maxLines: 2,
              ),
            ],
          ),

          // ── Save button ───────────────────────────────────────────
          if (widget.showSaveButton) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.saveMedicine),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Shared styled text field.
  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label: label, hint: hint),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  /// Shared styled dropdown.
  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) displayName,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: _inputDecoration(label: label),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(displayName(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark ? Colors.grey[900] : const Color(0xFFF8FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : const Color(0xFFDDE3F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : const Color(0xFFDDE3F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
      ),
      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Titled card that groups related form fields with an icon header.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: isDark ? Colors.grey[700] : null,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped schedule chip with icon and minimalist design.
class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppColors.primaryBlue;
    final unselectedColor = isDark ? Colors.grey[600]! : Colors.grey[300]!;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.12)
                : unselectedColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? accentColor : unselectedColor,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? accentColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? accentColor
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact toggle row with icon, label, and a switch.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
