import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/language_switcher.dart';

/// Screen for doctors to manually enter patient connection codes.
class DoctorCodeEntryScreen extends StatefulWidget {
  const DoctorCodeEntryScreen({super.key});

  @override
  State<DoctorCodeEntryScreen> createState() => _DoctorCodeEntryScreenState();
}

class _DoctorCodeEntryScreenState extends State<DoctorCodeEntryScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    setState(() => _isValidating = true);

    // Navigate to connection preview with the entered code
    if (mounted) {
      setState(() => _isValidating = false);
      Navigator.pushNamed(
        context,
        '/doctor/connection-preview',
        arguments: {'code': code},
      );
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.pleaseEnterCode;
    }
    final trimmed = value.trim();
    // Validate 8 alphanumeric characters
    if (trimmed.length != 8) {
      return AppLocalizations.of(context)!.invalidCode;
    }
    if (!RegExp(r'^[a-zA-Z0-9]{8}$').hasMatch(trimmed)) {
      return AppLocalizations.of(context)!.invalidCode;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enterCodeTitle),
        centerTitle: true,
        actions: const [LanguageSwitcherButton(lightBackground: true)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.password,
                    size: 40,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  l10n.enterConnectionCode,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.enterEightDigitFromPatient,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Code input
                TextFormField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    _UpperCaseTextFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: l10n.codeHintPlaceholder,
                    hintStyle: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                          color: AppColors.neutral300,
                          letterSpacing: 6,
                        ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: _validateCode,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Paste from clipboard
                TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      _codeController.text = data.text!
                          .trim()
                          .toUpperCase()
                          .substring(
                            0,
                            data.text!.trim().length > 8
                                ? 8
                                : data.text!.trim().length,
                          );
                    }
                  },
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: Text(l10n.pasteFromClipboard),
                ),

                const Spacer(),

                PrimaryButton(
                  text: l10n.continueButton,
                  isLoading: _isValidating,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Converts text to uppercase as user types.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
