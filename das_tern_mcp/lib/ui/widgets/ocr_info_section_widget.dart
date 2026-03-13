import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A reusable collapsible info section card for displaying extracted OCR data.
///
/// Displays a header with icon + title and a list of key-value info rows.
/// Sections can be collapsed/expanded. Designed for scalability — can display
/// patient info, prescriber info, facility info, clinical info, or metadata.
///
/// Usage:
/// ```dart
/// OcrInfoSectionWidget(
///   icon: Icons.person_outline,
///   title: 'Patient Information',
///   iconColor: AppColors.primaryBlue,
///   entries: [
///     OcrInfoEntry(label: 'Name', value: 'John Doe'),
///     OcrInfoEntry(label: 'Age', value: '25 years'),
///   ],
/// )
/// ```
class OcrInfoSectionWidget extends StatefulWidget {
  /// Icon displayed in the section header.
  final IconData icon;

  /// Title text for the section header.
  final String title;

  /// Color for the icon and header accent.
  final Color iconColor;

  /// List of key-value entries to display in the section body.
  final List<OcrInfoEntry> entries;

  /// Whether the section starts expanded. Defaults to true.
  final bool initiallyExpanded;

  /// Optional trailing widget in the header (e.g. a badge or status chip).
  final Widget? trailing;

  const OcrInfoSectionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.entries,
    this.iconColor = AppColors.primaryBlue,
    this.initiallyExpanded = true,
    this.trailing,
  });

  @override
  State<OcrInfoSectionWidget> createState() => _OcrInfoSectionWidgetState();
}

class _OcrInfoSectionWidgetState extends State<OcrInfoSectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    // Filter out entries with empty values unless a custom valueWidget is provided
    final visibleEntries = widget.entries
        .where((e) => e.valueWidget != null || e.value.isNotEmpty)
        .toList();

    if (visibleEntries.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: _isExpanded
              ? widget.iconColor.withValues(alpha: 0.3)
              : AppColors.neutral300,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.md),
              bottom: _isExpanded
                  ? Radius.zero
                  : const Radius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    widget.trailing!,
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Body
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: visibleEntries
                    .map((entry) => _buildEntryRow(context, entry))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, OcrInfoEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '${entry.label}:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child:
                entry.valueWidget ??
                Text(
                  entry.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: entry.valueColor,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// A single key-value entry for [OcrInfoSectionWidget].
class OcrInfoEntry {
  /// Label displayed on the left.
  final String label;

  /// Text value displayed on the right. If empty, the entry is hidden.
  final String value;

  /// Optional color override for the value text.
  final Color? valueColor;

  /// Optional custom widget instead of plain text for the value.
  final Widget? valueWidget;

  const OcrInfoEntry({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWidget,
  });
}
