import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/drift/app_database.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass/app_glass_card.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../../shared/widgets/states/error_state.dart';
import '../../../../shared/widgets/states/loading_state.dart';

/// Shows the version history of a prescription with per-version diffs.
/// Spec ref: 03-prescription-medication §4.4.
class VersionHistoryPage extends ConsumerWidget {
  const VersionHistoryPage({super.key, required this.prescriptionId});

  final String prescriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final db = ref.watch(appDatabaseProvider);

    return AppScaffold(
      title: l.doseHistory,
      body: FutureBuilder<List<PrescriptionVersionsTableData>>(
        future: (db.select(db.prescriptionVersionsTable)
              ..where((t) => t.prescriptionId.equals(prescriptionId))
              ..orderBy([(t) => OrderingTerm.desc(t.versionNumber)]))
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snap.hasError) {
            return ErrorState(message: snap.error.toString());
          }
          final versions = snap.data ?? [];
          if (versions.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No version history yet',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kToolbarHeight + AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            itemCount: versions.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final v = versions[i];
              final prev = i + 1 < versions.length ? versions[i + 1] : null;
              return _VersionCard(version: v, previous: prev);
            },
          );
        },
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.version, this.previous});

  final PrescriptionVersionsTableData version;
  final PrescriptionVersionsTableData? previous;

  List<String> _diff() {
    if (previous == null) return <String>['Initial version'];
    try {
      final curr = (jsonDecode(version.medicationsSnapshot) as List)
          .cast<Map<String, dynamic>>();
      final prev = (jsonDecode(previous!.medicationsSnapshot) as List)
          .cast<Map<String, dynamic>>();
      final changes = <String>[];
      for (var i = 0; i < curr.length; i++) {
        final c = curr[i];
        final p = i < prev.length ? prev[i] : null;
        if (p == null) {
          changes.add('+ Added ${c['medicine_name']}');
        } else {
          if (c['dosage_amount'] != p['dosage_amount']) {
            changes.add(
              '~ ${c['medicine_name']}: dosage '
              '${p['dosage_amount']} → ${c['dosage_amount']}',
            );
          }
          if (c['frequency'] != p['frequency']) {
            changes.add(
              '~ ${c['medicine_name']}: frequency '
              '${p['frequency']} → ${c['frequency']}',
            );
          }
        }
      }
      if (changes.isEmpty) changes.add('Minor update');
      return changes;
    } catch (_) {
      return <String>['Version ${version.versionNumber}'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffs = _diff();
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'v${version.versionNumber}',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                version.createdAt.toLocal().toString().substring(0, 16),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          if (version.changeReason != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(version.changeReason!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          ...diffs.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(d, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
