import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Screen for manual code entry (alternative to QR scanning).
class CodeEntryScreen extends StatefulWidget {
  const CodeEntryScreen({super.key});

  @override
  State<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends State<CodeEntryScreen> {
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

    // Navigate to preview with the entered token
    if (mounted) {
      setState(() => _isValidating = false);
      Navigator.pushNamed(
        context,
        '/family/preview',
        arguments: {'token': code},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('បញ្ចូលកូដ'),
        centerTitle: true,
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
                  'បញ្ចូលកូដតភ្ជាប់',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'សូមបញ្ចូលកូដ ៨ ខ្ទង់ពីអ្នកជំងឺ',
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
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_\-]')),
                    UpperCaseTextFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: 'XXXXXXXX',
                    hintStyle:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'សូមបញ្ចូលកូដ';
                    }
                    if (value.trim().length < 6) {
                      return 'កូដមិនត្រឹមត្រូវ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Paste from clipboard
                TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      _codeController.text = data.text!.trim();
                    }
                  },
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('បិទភ្ជាប់ពីក្ដារចម្លង'),
                ),

                const Spacer(),

                PrimaryButton(
                  text: 'បន្ត',
                  isLoading: _isValidating,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  text: 'ស្កេនកូដ QR ជំនួស',
                  isOutlined: true,
                  icon: Icons.qr_code_scanner,
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/family/scan');
                  },
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
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
    );
  }
}
