import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/radii.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass/app_glass_card.dart';
import '../../domain/chosen_role.dart';

class RoleChooserCard extends StatelessWidget {
  const RoleChooserCard({
    super.key,
    required this.role,
    required this.onTap,
  });

  final ChosenRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isPatient = role == ChosenRole.patient;
    final icon = isPatient ? Icons.person_outline : Icons.medical_services_outlined;
    final title = isPatient ? l.patientRole : l.doctorRole;
    final subtitle = isPatient ? l.patientRoleDescription : l.doctorRoleDescription;

    return AppGlassCard(
      onTap: onTap,
      borderRadius: AppRadii.allLarge,
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: AppRadii.allMedium,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
