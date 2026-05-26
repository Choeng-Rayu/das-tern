import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../../../shared/widgets/cards/app_card.dart';

/// Diagnostics screen — build info, environment, sync state.
/// Developer-facing only; strings are intentionally English.
///
/// Spec ref: 00-overview/tasks.md Phase 5 §5.4.
class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = AppConfig.fromEnvironment();
    final engine = ref.watch(syncEngineProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: FutureBuilder<_DiagData>(
        future: _load(engine),
        builder: (context, snap) {
          final data = snap.data;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _Section(
                title: 'App',
                rows: [
                  _Row('Version', data?.version ?? '…'),
                  _Row('Build', data?.buildNumber ?? '…'),
                  _Row('Environment', config.environment),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Section(
                title: 'Sync',
                rows: [
                  _Row('Online', isOnline ? '✓' : '✗'),
                  _Row('Outbox depth', '${data?.outboxDepth ?? '…'}'),
                  _Row(
                    'Last sync',
                    engine.lastSyncAt?.toLocal().toString() ?? 'never',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Section(
                title: 'Supabase',
                rows: [
                  _Row(
                    'URL',
                    config.supabaseUrl.isEmpty
                        ? '(not set)'
                        : config.supabaseUrl,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_DiagData> _load(SyncEngine engine) async {
    final info = await PackageInfo.fromPlatform();
    final depth = await engine.depth();
    return _DiagData(
      version: info.version,
      buildNumber: info.buildNumber,
      outboxDepth: depth,
    );
  }
}

class _DiagData {
  const _DiagData({
    required this.version,
    required this.buildNumber,
    required this.outboxDepth,
  });
  final String version;
  final String buildNumber;
  final int outboxDepth;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        AppCard(
          child: Column(
            children: rows
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Flexible(
                          child: Text(
                            r.value,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}
