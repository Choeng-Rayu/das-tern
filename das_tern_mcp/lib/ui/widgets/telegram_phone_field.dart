import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/country_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Telegram-style phone number input with country selector.
///
/// Layout: `[Flag+Code ▼ | Phone Input]`
/// - Tapping the left section opens a searchable country bottom sheet
/// - Auto-detects country when pasting a number starting with +
/// - Provides [fullPhoneNumber] combining dialCode + local digits
class TelegramStylePhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Country? initialCountry;

  const TelegramStylePhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.initialCountry,
  });

  @override
  State<TelegramStylePhoneField> createState() =>
      TelegramStylePhoneFieldState();
}

class TelegramStylePhoneFieldState extends State<TelegramStylePhoneField> {
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? Country.defaultCountry;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  /// Full phone number: +{dialCode}{localDigits}
  String get fullPhoneNumber {
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    return '+${_selectedCountry.dialCode}$digits';
  }

  Country get selectedCountry => _selectedCountry;

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.startsWith('+')) {
      final detected = Country.detectFromNumber(text);
      if (detected != null && detected.code != _selectedCountry.code) {
        setState(() => _selectedCountry = detected);
        // Strip the dial code prefix from input
        final prefix = '+${detected.dialCode}';
        if (text.startsWith(prefix)) {
          widget.controller.text = text.substring(prefix.length);
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }
      }
    }
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onSelected: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          // Country selector button
          GestureDetector(
            onTap: _openCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: AppColors.neutral300.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCountry.displayDialCode,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Phone number input
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: l10n.phoneExample(_selectedCountry.exampleNumber),
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with searchable country list.
class _CountryPickerSheet extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onSelected;

  const _CountryPickerSheet({
    required this.selectedCountry,
    required this.onSelected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<Country> _filtered = Country.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = Country.all.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.nameKm.contains(q) ||
            c.dialCode.contains(q) ||
            c.code.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.selectCountry,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: l10n.searchCountry,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.neutral200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Country list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  final isSelected =
                      country.code == widget.selectedCountry.code;

                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country.name),
                    subtitle: Text(country.nameKm),
                    trailing: Text(
                      country.displayDialCode,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor:
                        AppColors.primaryBlue.withValues(alpha: 0.06),
                    onTap: () => widget.onSelected(country),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
