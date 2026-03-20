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
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────

  MedicineType _medicineType = MedicineType.oral;
  MedicineUnit _unit = MedicineUnit.tablet;
  int _frequencyPerDay = 1; // 1–4 times per day (drives max slot selection)
  bool _morning = true;
  bool _afternoon = false;
  bool _evening = false;
  bool _night = false;
  // 'BEFORE_MEAL' | 'AFTER_MEAL' | 'WITH_FOOD' | 'NONE'
  String _mealTiming = 'NONE';
  bool _isPRN = false;

  // Time-of-day defaults for each period (user-editable via time picker)
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _nightTime = const TimeOfDay(hour: 21, minute: 0);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameController.text = d['medicineName'] ?? '';
      _nameKhmerController.text = d['medicineNameKhmer'] ?? '';
      _dosageController.text = (d['dosageAmount'] ?? '').toString();
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
      _afternoon = d['afternoonDosage'] != null
          ? true
          : (d['afternoon'] ?? false);
      _evening = d['eveningDosage'] != null ? true : (d['evening'] ?? false);
      _night = d['nightDosage'] != null ? true : (d['night'] ?? false);
      // Parse frequency number from stored string (e.g. "2x/day" → 2)
      final freqStr = d['frequency'] as String? ?? '';
      final freqMatch = RegExp(r'\d+').firstMatch(freqStr);
      _frequencyPerDay = freqMatch != null
          ? (int.tryParse(freqMatch.group(0)!) ?? 1).clamp(1, 4)
          : 1;
      // Restore meal timing (new field takes precedence over legacy bool)
      final mt = d['mealTiming'] as String?;
      if (mt != null && mt.isNotEmpty) {
        _mealTiming = mt;
      } else if (d['beforeMeal'] == true) {
        _mealTiming = 'BEFORE_MEAL';
      }
      _isPRN = d['isPRN'] ?? false;
      // Restore per-period times from scheduleTimes if present
      final schedTimes = d['scheduleTimes'];
      if (schedTimes is List) {
        for (final st in schedTimes) {
          final period = st['timePeriod'] as String?;
          final timeStr = st['time'] as String?;
          if (period == null || timeStr == null) continue;
          final parts = timeStr.split(':');
          if (parts.length < 2) continue;
          final tod = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
          if (period == 'MORNING') { _morningTime = tod; }
          else if (period == 'AFTERNOON') { _afternoonTime = tod; }
          else if (period == 'EVENING') { _eveningTime = tod; }
          else if (period == 'NIGHT') { _nightTime = tod; }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameKhmerController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Returns how many time slots are currently selected.
  int get _selectedSlotCount =>
      [_morning, _afternoon, _evening, _night].where((b) => b).length;

  String _formatTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Auto-enable the next unselected default slot when frequency is increased.
  /// Order: Morning → Afternoon → Night → Evening (typical medication pattern).
  void _autoEnableNextSlot() {
    if (!_morning) { _morning = true; return; }
    if (!_afternoon) { _afternoon = true; return; }
    if (!_night) { _night = true; return; }
    if (!_evening) { _evening = true; return; }
  }
  Future<void> _pickTime(
    TimeOfDay current,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  /// Attempt to toggle a time slot; enforces the frequency-per-day limit.
  void _toggleSlot(void Function() toggle, bool currentValue) {
    if (!currentValue && _selectedSlotCount >= _frequencyPerDay) {
      // Already at limit – show feedback instead of toggling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $_frequencyPerDay slot(s) allowed for this frequency.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(toggle);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final beforeMeal = _mealTiming == 'BEFORE_MEAL';

    // Build scheduleTimes from selected time slots.
    // Backend DTO expects: {timePeriod: 'MORNING'|'AFTERNOON'|'EVENING'|'NIGHT', time: 'HH:MM'}
    final scheduleTimes = <Map<String, String>>[];
    if (!_isPRN) {
      if (_morning) {
        scheduleTimes.add({'timePeriod': 'MORNING', 'time': _formatTod(_morningTime)});
      }
      if (_afternoon) {
        scheduleTimes.add({'timePeriod': 'AFTERNOON', 'time': _formatTod(_afternoonTime)});
      }
      if (_evening) {
        scheduleTimes.add({'timePeriod': 'EVENING', 'time': _formatTod(_eveningTime)});
      }
      if (_night) {
        scheduleTimes.add({'timePeriod': 'NIGHT', 'time': _formatTod(_nightTime)});
      }
      // Fallback: if user set frequency > 0 but selected no slots, auto-fill defaults
      if (scheduleTimes.isEmpty) {
        const defaultOrder = [
          ['MORNING', 'morning'],
          ['AFTERNOON', 'afternoon'],
          ['NIGHT', 'night'],
          ['EVENING', 'evening'],
        ];
        for (int i = 0; i < _frequencyPerDay && i < defaultOrder.length; i++) {
          final period = defaultOrder[i][0];
          final tod = period == 'MORNING' ? _morningTime
              : period == 'AFTERNOON' ? _afternoonTime
              : period == 'NIGHT' ? _nightTime
              : _eveningTime;
          scheduleTimes.add({'timePeriod': period, 'time': _formatTod(tod)});
        }
      }
    }

    widget.onSave({
      'medicineName': _nameController.text.trim(),
      'medicineNameKhmer': _nameKhmerController.text.trim(),
      'medicineType': _medicineType.toJson(),
      'unit': _unit.toJson(),
      // Required by backend DTO
      'dosageUnit': _unit.displayName,
      'form': _medicineType.displayName,
      'dosageAmount': double.tryParse(_dosageController.text) ?? 1,
      'frequency': '${_frequencyPerDay}x/day',
      'durationDays': int.tryParse(_durationController.text) ?? 30,
      'scheduleTimes': scheduleTimes,
      'beforeMeal': beforeMeal,
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
                  // Frequency stepper (1–4 times per day)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.frequency,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StepperButton(
                              icon: Icons.remove,
                              onPressed: _frequencyPerDay > 1
                                  ? () => setState(() {
                                      _frequencyPerDay--;
                                      // Deselect excess slots
                                      final slots = [
                                        if (_night) 'night',
                                        if (_evening) 'evening',
                                        if (_afternoon) 'afternoon',
                                        if (_morning) 'morning',
                                      ];
                                      while (slots.length > _frequencyPerDay) {
                                        final excess = slots.removeAt(0);
                                        if (excess == 'night') { _night = false; }
                                        if (excess == 'evening') {
                                          _evening = false;
                                        }
                                        if (excess == 'afternoon') {
                                          _afternoon = false;
                                        }
                                        if (excess == 'morning') {
                                          _morning = false;
                                        }
                                      }
                                    })
                                  : null,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_frequencyPerDay×/day',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add,
                              onPressed: _frequencyPerDay < 4
                                  ? () => setState(() {
                                      _frequencyPerDay++;
                                      // Auto-enable the next default slot
                                      if (!_isPRN) _autoEnableNextSlot();
                                    })
                                  : null,
                            ),
                          ],
                        ),
                      ],
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
              // Time-of-day chips (hidden when PRN)
              if (!_isPRN) ...[
                Row(
                  children: [
                    _ScheduleChip(
                      label: l10n.morning,
                      icon: Icons.wb_sunny_rounded,
                      selected: _morning,
                      onTap: () =>
                          _toggleSlot(() => _morning = !_morning, _morning),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ScheduleChip(
                      label: l10n.afternoon,
                      icon: Icons.wb_twilight,
                      color: const Color(0xFF26C6DA),
                      selected: _afternoon,
                      onTap: () => _toggleSlot(
                        () => _afternoon = !_afternoon,
                        _afternoon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _ScheduleChip(
                      label: l10n.evening,
                      icon: Icons.wb_cloudy_outlined,
                      color: const Color(0xFFFF7043),
                      selected: _evening,
                      onTap: () =>
                          _toggleSlot(() => _evening = !_evening, _evening),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ScheduleChip(
                      label: l10n.night,
                      icon: Icons.nightlight_round,
                      selected: _night,
                      onTap: () => _toggleSlot(() => _night = !_night, _night),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // ── Per-slot time pickers ──────────────────────────────────
                if (_morning || _afternoon || _evening || _night) ...[
                  const SizedBox(height: AppSpacing.xs),
                  if (_morning)
                    _SlotTimeTile(
                      label: l10n.morning,
                      icon: Icons.wb_sunny_rounded,
                      color: AppColors.primaryBlue,
                      time: _morningTime,
                      onTap: () => _pickTime(
                        _morningTime,
                        (t) => _morningTime = t,
                      ),
                    ),
                  if (_afternoon)
                    _SlotTimeTile(
                      label: l10n.afternoon,
                      icon: Icons.wb_twilight,
                      color: const Color(0xFF26C6DA),
                      time: _afternoonTime,
                      onTap: () => _pickTime(
                        _afternoonTime,
                        (t) => _afternoonTime = t,
                      ),
                    ),
                  if (_evening)
                    _SlotTimeTile(
                      label: l10n.evening,
                      icon: Icons.wb_cloudy_outlined,
                      color: const Color(0xFFFF7043),
                      time: _eveningTime,
                      onTap: () => _pickTime(
                        _eveningTime,
                        (t) => _eveningTime = t,
                      ),
                    ),
                  if (_night)
                    _SlotTimeTile(
                      label: l10n.night,
                      icon: Icons.nightlight_round,
                      color: AppColors.primaryBlue,
                      time: _nightTime,
                      onTap: () => _pickTime(
                        _nightTime,
                        (t) => _nightTime = t,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),

                // Meal timing — 3-option segmented control
                Row(
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'BEFORE_MEAL',
                            label: Text(
                              l10n.beforeMeal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ButtonSegment(
                            value: 'AFTER_MEAL',
                            label: Text(
                              l10n.afterMeal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ButtonSegment(
                            value: 'WITH_FOOD',
                            label: Text(
                              l10n.withFood,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        selected: _mealTiming == 'NONE' ? {} : {_mealTiming},
                        emptySelectionAllowed: true,
                        multiSelectionEnabled: false,
                        style: ButtonStyle(
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 11),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          visualDensity: const VisualDensity(
                            horizontal: -1,
                            vertical: -1,
                          ),
                        ),
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _mealTiming = newSelection.isEmpty
                                ? 'NONE'
                                : newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Divider(height: 1),
              ],

              // PRN toggle + subtitle
              _ToggleRow(
                icon: Icons.access_time_outlined,
                label: l10n.prn,
                subtitle: l10n.prnDescription,
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
      isExpanded: true,
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
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
    this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = color ?? AppColors.primaryBlue;
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

/// Compact toggle row with icon, label, optional subtitle, and a switch.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
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

/// Small +/- button used in the frequency stepper.
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: onPressed != null
            ? AppColors.primaryBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null
                ? AppColors.primaryBlue
                : AppColors.neutral300,
          ),
        ),
      ),
    );
  }
}

/// Compact row showing a period's icon, label, and selected time.
/// Tapping opens a system time picker.
class _SlotTimeTile extends StatelessWidget {
  const _SlotTimeTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.time,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
