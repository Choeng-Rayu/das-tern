import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass/app_glass_card.dart';
import '../../../../shared/widgets/glass/app_glass_chip.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../../shared/widgets/states/error_state.dart';
import '../../../../shared/widgets/states/loading_state.dart';
import '../../domain/prescription.dart';
import '../../domain/prescription_enums.dart';
import '../providers/prescription_providers.dart';

class PrescriptionListPage extends ConsumerStatefulWidget {
  const PrescriptionListPage({super.key});

  @override
  ConsumerState<PrescriptionListPage> createState() =>
      _PrescriptionListPageState();
}

class _PrescriptionListPageState extends ConsumerState<PrescriptionListPage> {
  final _searchCtrl = TextEditingController();
  PrescriptionStatus? _filterStatus;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Prescription> _filter(List<Prescription> all) {
    var list = all;
    if (_filterStatus != null) {
      list = list.where((p) => p.status == _filterStatus).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (p) =>
                p.patientName.toLowerCase().contains(q) ||
                p.symptoms.toLowerCase().contains(q) ||
                (p.diagnosis?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final asyncList = ref.watch(prescriptionsByPatientProvider(uid));

    return AppScaffold(
      title: l.savePrescription,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => context.push('/patient/prescriptions/new'),
        ),
      ],
      body: Column(
        children: <Widget>[
          // Search + filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kToolbarHeight + AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: <Widget>[
                AppTextField(
                  controller: _searchCtrl,
                  label: l.searchPrescription,
                  prefixIcon: Icons.search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      AppGlassChip(
                        label: 'All',
                        selected: _filterStatus == null,
                        onTap: () => setState(() => _filterStatus = null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...PrescriptionStatus.values.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: AppGlassChip(
                            label: s.code,
                            selected: _filterStatus == s,
                            color: _statusColor(s),
                            onTap: () =>
                                setState(() => _filterStatus = s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: asyncList.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(prescriptionsByPatientProvider(uid)),
              ),
              data: (items) {
                final filtered = _filter(items);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.medication_outlined,
                    title: l.doseHistoryAppearHere,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _PrescriptionCard(
                    prescription: filtered[i],
                    onTap: () => context
                        .push('/patient/prescriptions/${filtered[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PrescriptionStatus s) => switch (s) {
        PrescriptionStatus.active => const Color(0xFF1FAA66),
        PrescriptionStatus.paused => const Color(0xFFF1A93A),
        PrescriptionStatus.inactive => const Color(0xFFD64545),
        PrescriptionStatus.draft => Colors.grey,
      };
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.onTap,
  });

  final Prescription prescription;
  final VoidCallback onTap;

  Color _statusColor(PrescriptionStatus s) => switch (s) {
        PrescriptionStatus.active => const Color(0xFF1FAA66),
        PrescriptionStatus.paused => const Color(0xFFF1A93A),
        PrescriptionStatus.inactive => const Color(0xFFD64545),
        PrescriptionStatus.draft => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(prescription.patientName,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  prescription.symptoms,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppGlassChip(
            label: prescription.status.code,
            color: _statusColor(prescription.status),
          ),
        ],
      ),
    );
  }
}
