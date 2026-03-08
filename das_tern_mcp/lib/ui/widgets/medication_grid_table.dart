import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Row data for a single medication in the grid table.
class MedicationGridRow {
  String medicineName;
  String medicineNameKhmer;
  String? morningDosage;
  String? daytimeDosage;
  String? nightDosage;
  bool beforeMeal;

  MedicationGridRow({
    this.medicineName = '',
    this.medicineNameKhmer = '',
    this.morningDosage,
    this.daytimeDosage,
    this.nightDosage,
    this.beforeMeal = true,
  });

  /// Convert from the Map<String, dynamic> format used by [PrescriptionMedication].
  factory MedicationGridRow.fromMedicationMap(Map<String, dynamic> map) {
    return MedicationGridRow(
      medicineName: map['medicineName'] as String? ?? '',
      medicineNameKhmer: map['medicineNameKhmer'] as String? ?? '',
      morningDosage: _extractDosage(map['morningDosage']),
      daytimeDosage: _extractDosage(map['daytimeDosage']),
      nightDosage: _extractDosage(map['nightDosage']),
      beforeMeal: map['beforeMeal'] as bool? ?? true,
    );
  }

  /// Convert back to a Map<String, dynamic> for submission.
  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'medicineNameKhmer': medicineNameKhmer,
      if (morningDosage != null && morningDosage!.isNotEmpty)
        'morningDosage': {'amount': morningDosage},
      if (daytimeDosage != null && daytimeDosage!.isNotEmpty)
        'daytimeDosage': {'amount': daytimeDosage},
      if (nightDosage != null && nightDosage!.isNotEmpty)
        'nightDosage': {'amount': nightDosage},
      'beforeMeal': beforeMeal,
      'frequency': _buildFrequency(),
      'timing': _buildTiming(),
    };
  }

  String _buildFrequency() {
    int count = 0;
    if (morningDosage != null && morningDosage!.isNotEmpty) count++;
    if (daytimeDosage != null && daytimeDosage!.isNotEmpty) count++;
    if (nightDosage != null && nightDosage!.isNotEmpty) count++;
    return '$count times/day';
  }

  String _buildTiming() {
    final parts = <String>[];
    if (morningDosage != null && morningDosage!.isNotEmpty) parts.add('morning');
    if (daytimeDosage != null && daytimeDosage!.isNotEmpty) parts.add('daytime');
    if (nightDosage != null && nightDosage!.isNotEmpty) parts.add('night');
    return parts.join(', ');
  }

  static String? _extractDosage(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final amount = value['amount'];
      return amount?.toString();
    }
    if (value is num) return value.toString();
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}

/// Tabular medication grid with columns: Row#, Name, Morning, Daytime, Night.
///
/// Supports `editable` mode (for prescription creation) with inline
/// text fields and add/remove actions, and `read-only` mode for viewing
/// existing prescription details.
class MedicationGridTable extends StatelessWidget {
  final List<MedicationGridRow> rows;
  final bool editable;
  final ValueChanged<List<MedicationGridRow>>? onRowsChanged;

  const MedicationGridTable({
    super.key,
    required this.rows,
    this.editable = false,
    this.onRowsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        _buildHeaderRow(context, l10n),
        const Divider(height: 1),

        // Data rows
        ...rows.asMap().entries.map((entry) {
          return _buildDataRow(context, l10n, entry.key, entry.value);
        }),

        // Add row button (editable only)
        if (editable) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () {
              final updated = List<MedicationGridRow>.from(rows)
                ..add(MedicationGridRow());
              onRowsChanged?.call(updated);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addRow),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, AppLocalizations l10n) {
    final headerStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      color: AppColors.neutral200,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#', style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(l10n.medicineName, style: headerStyle),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(l10n.morning, style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 1,
            child: Text(l10n.daytime, style: headerStyle, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 1,
            child: Text(l10n.night, style: headerStyle, textAlign: TextAlign.center),
          ),
          if (editable) const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    MedicationGridRow row,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Row number
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          // Medicine name
          Expanded(
            flex: 3,
            child: editable
                ? Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EditableCell(
                          value: row.medicineName,
                          hint: l10n.medicineName,
                          onChanged: (v) {
                            row.medicineName = v;
                            onRowsChanged?.call(List.from(rows));
                          },
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            row.beforeMeal = !row.beforeMeal;
                            onRowsChanged?.call(List.from(rows));
                          },
                          child: Text(
                            row.beforeMeal ? l10n.beforeMeal : '${l10n.beforeMeal} ✗',
                            style: TextStyle(
                              fontSize: 10,
                              color: row.beforeMeal
                                  ? AppColors.successGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.medicineName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        if (row.medicineNameKhmer.isNotEmpty)
                          Text(
                            row.medicineNameKhmer,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          row.beforeMeal ? l10n.beforeMeal : '${l10n.beforeMeal} ✗',
                          style: TextStyle(
                            fontSize: 10,
                            color: row.beforeMeal
                                ? AppColors.successGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Morning dosage
          Expanded(
            flex: 1,
            child: editable
                ? _EditableCell(
                    value: row.morningDosage ?? '',
                    hint: '-',
                    onChanged: (v) {
                      row.morningDosage = v.isEmpty ? null : v;
                      onRowsChanged?.call(List.from(rows));
                    },
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.text,
                  )
                : _DosageCell(value: row.morningDosage),
          ),

          // Daytime dosage
          Expanded(
            flex: 1,
            child: editable
                ? _EditableCell(
                    value: row.daytimeDosage ?? '',
                    hint: '-',
                    onChanged: (v) {
                      row.daytimeDosage = v.isEmpty ? null : v;
                      onRowsChanged?.call(List.from(rows));
                    },
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.text,
                  )
                : _DosageCell(value: row.daytimeDosage),
          ),

          // Night dosage
          Expanded(
            flex: 1,
            child: editable
                ? _EditableCell(
                    value: row.nightDosage ?? '',
                    hint: '-',
                    onChanged: (v) {
                      row.nightDosage = v.isEmpty ? null : v;
                      onRowsChanged?.call(List.from(rows));
                    },
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.text,
                  )
                : _DosageCell(value: row.nightDosage),
          ),

          // Delete button (editable)
          if (editable)
            SizedBox(
              width: 36,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.alertRed),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final updated = List<MedicationGridRow>.from(rows)..removeAt(index);
                  onRowsChanged?.call(updated);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Read-only dosage cell showing the value or a dash.
class _DosageCell extends StatelessWidget {
  final String? value;

  const _DosageCell({this.value});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Text(
      hasValue ? value! : '-',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
            color: hasValue ? AppColors.textPrimary : AppColors.neutral400,
          ),
    );
  }
}

/// Inline editable text cell for the grid.
class _EditableCell extends StatelessWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextAlign textAlign;
  final TextInputType keyboardType;

  const _EditableCell({
    required this.value,
    required this.hint,
    required this.onChanged,
    this.textAlign = TextAlign.start,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      textAlign: textAlign,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.neutral400),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
      ),
    );
  }
}
