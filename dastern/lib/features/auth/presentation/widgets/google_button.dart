import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/radii.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// Brand-compliant Google sign-in button.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.allMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Google "G" icon using a coloured text approximation
          const Text(
            'G',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(l.signInWithGoogle),
        ],
      ),
    );
  }
}
