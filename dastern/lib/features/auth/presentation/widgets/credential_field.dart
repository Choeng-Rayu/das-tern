import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/credential_kind_detector.dart';

/// Text field that accepts email or phone and validates accordingly.
class CredentialField extends StatelessWidget {
  const CredentialField({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppTextField(
      controller: controller,
      label: l.phoneNumber,
      hint: l.phoneNumberHint,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return l.phoneNumberEmpty;
        if (CredentialKindDetector.detect(v) == CredentialKind.unknown) {
          return l.phoneNumberInvalid;
        }
        return null;
      },
    );
  }
}
