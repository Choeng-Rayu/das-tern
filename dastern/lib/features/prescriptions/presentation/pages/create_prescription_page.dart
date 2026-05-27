import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../../core/storage/drift/daos/dose_events_dao.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/schedule_generator.dart';
import '../../domain/prescription_enums.dart';
import '../../domain/usecases/create_prescription.dart';
import '../providers/prescription_providers.dart';
import '../widgets/freemium_upgrade_sheet.dart';

class CreatePrescriptionPage extends ConsumerStatefulWidget {
  const CreatePrescriptionPage({super.key});

  @override
  ConsumerState<CreatePrescriptionPage> createState() =>
      _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState
    extends ConsumerState<CreatePrescriptionPage> {
  final _nameCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Gender _gender = Gender.male;
  int _age = 25;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    setState(() { _loading = true; _error = null; });
    try {
      tz_data.initializeTimeZones();
      final db = ref.read(appDatabaseProvider);
      final sync = ref.read(syncEngineProvider);
      final useCase = CreatePrescription(
        ref.read(prescriptionRepositoryProvider),
        ref.read(medicationRepositoryProvider),
        const ScheduleGenerator(MealTimePreference.cambodiaDefaults),
        DoseEventsDao(db),
        sync,
      );
      final p = await useCase(
        PrescriptionDraft(
          patientId: uid,
          patientName: _nameCtrl.text.trim(),
          patientGender: _gender,
          patientAge: _age,
          symptoms: _symptomsCtrl.text.trim(),
          diagnosis: _diagnosisCtrl.text.trim().isEmpty
              ? null
              : _diagnosisCtrl.text.trim(),
          medications: const <Map<String, dynamic>>[],
          patientTimezone: 'Asia/Phnom_Penh',
        ),
      );
      if (mounted) {
        ref.invalidate(prescriptionsByPatientProvider(uid));
        context.go('/patient/prescriptions/${p.id}');
      }
    } catch (e) {
      if (mounted) {
        final handled = await handleFreemiumError(context, e);
        if (!handled) setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l.savePrescription,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          kToolbarHeight + AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                controller: _nameCtrl,
                label: l.fullName,
                hint: l.fullNameHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.fullNameError : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _symptomsCtrl,
                label: 'Symptoms',
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _diagnosisCtrl,
                label: 'Diagnosis (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<Gender>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: Gender.values
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.code),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gender = v ?? Gender.male),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  const Text('Age: '),
                  Expanded(
                    child: Slider(
                      value: _age.toDouble(),
                      min: 1,
                      max: 120,
                      divisions: 119,
                      label: '$_age',
                      onChanged: (v) => setState(() => _age = v.round()),
                    ),
                  ),
                  Text('$_age'),
                ],
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.save,
                onPressed: _loading ? null : _create,
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
