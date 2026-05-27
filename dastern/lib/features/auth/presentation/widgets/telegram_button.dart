import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/radii.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';

class TelegramButton extends StatelessWidget {
  const TelegramButton({super.key, required this.onPressed});
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
          const Icon(Icons.send, color: Color(0xFF2AABEE), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(l.signInWithTelegram),
        ],
      ),
    );
  }
}
