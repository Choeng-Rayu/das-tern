import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/tokens/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass/app_scaffold.dart';
import '../../auth/presentation/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l.settings,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoute.home),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + 8),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.appearance),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.settingsAppearance),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Diagnostics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.settingsDiagnostics),
          ),
          const Divider(),
          // ── Account ──────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export my data'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppColors.danger),
            title: const Text('Delete account',
                style: TextStyle(color: AppColors.danger)),
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'account-export',
        method: HttpMethod.post,
      );
      if (res.status == 200) {
        final url = (res.data as Map<String, dynamic>)['url'] as String;
        await launchUrl(Uri.parse(url));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and all data. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await Supabase.instance.client.functions.invoke(
        'account-delete',
        method: HttpMethod.delete,
      );
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deletion failed. Please try again.')),
        );
      }
    }
  }
}
