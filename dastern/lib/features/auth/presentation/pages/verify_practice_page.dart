import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

/// Optional doctor verification flow.
/// Collects professional info and sets account_status = 'PENDING_VERIFICATION'.
///
/// Spec ref: 02-authentication §8.6.
class VerifyPracticePage extends ConsumerStatefulWidget {
  const VerifyPracticePage({super.key});

  @override
  ConsumerState<VerifyPracticePage> createState() => _VerifyPracticePageState();
}

class _VerifyPracticePageState extends ConsumerState<VerifyPracticePage> {
  final _hospitalCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _hospitalCtrl.dispose();
    _specialtyCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.from('profiles').update(<String, dynamic>{
        'hospital_clinic': _hospitalCtrl.text.trim().isEmpty
            ? null
            : _hospitalCtrl.text.trim(),
        'specialty': _specialtyCtrl.text.trim().isEmpty
            ? null
            : _specialtyCtrl.text.trim(),
        'license_number': _licenseCtrl.text.trim().isEmpty
            ? null
            : _licenseCtrl.text.trim(),
        'account_status': 'PENDING_VERIFICATION',
      }).eq('id', uid);
      if (mounted) context.pop();
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
      title: l.professionalInfoSection,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(l.accountVerificationInfo,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _hospitalCtrl,
              label: l.hospitalClinic,
              hint: l.hospitalClinicHint,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _specialtyCtrl,
              label: l.specialty,
              hint: l.specialtyHint,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _licenseCtrl,
              label: l.medicalLicense,
              hint: l.medicalLicenseHint,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l.save,
              onPressed: _loading ? null : _submit,
              loading: _loading,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
