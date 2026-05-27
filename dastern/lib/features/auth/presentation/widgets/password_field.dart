import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/colors.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.showStrength = false,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final bool showStrength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  double _strength(String v) {
    if (v.length < 6) return 0.2;
    var score = 0.4;
    if (v.length >= 8) score += 0.2;
    if (RegExp('[A-Z]').hasMatch(v)) score += 0.1;
    if (RegExp('[0-9]').hasMatch(v)) score += 0.1;
    if (RegExp('[^A-Za-z0-9]').hasMatch(v)) score += 0.2;
    return score.clamp(0.0, 1.0);
  }

  Color _strengthColor(double s) {
    if (s < 0.4) return AppColors.danger;
    if (s < 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: widget.controller,
          label: widget.label ?? l.forgotPassword, // reuse as "Password"
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: widget.onSubmitted,
          validator: widget.validator,
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        if (widget.showStrength)
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, child) {
              final s = _strength(widget.controller.text);
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: s,
                  color: _strengthColor(s),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHigh,
                  minHeight: 4,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              );
            },
          ),
      ],
    );
  }
}
