import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

class ProfileBootstrapPage extends ConsumerStatefulWidget {
  const ProfileBootstrapPage({super.key});

  @override
  ConsumerState<ProfileBootstrapPage> createState() =>
      _ProfileBootstrapPageState();
}

class _ProfileBootstrapPageState extends ConsumerState<ProfileBootstrapPage> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) { context.go('/welcome'); return; }
      await Supabase.instance.client
          .from('profiles')
          .update(<String, dynamic>{'full_name': _nameCtrl.text.trim()})
          .eq('id', uid);
      if (mounted) context.go('/patient/home');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l.personalInfoSection,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _nameCtrl,
                label: l.fullName,
                hint: l.fullNameHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.fullNameError : null,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              AppButton(
                label: l.save,
                onPressed: _loading ? null : _save,
                loading: _loading,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
