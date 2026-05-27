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

/// Doctor-facing prescription authoring page.
/// Spec ref: 03-prescription-medication design §7.
class DoctorPrescriptionAuthoringPage extends ConsumerStatefulWidget {
  const DoctorPrescriptionAuthoringPage({
    super.key,
    required this.patientId,
  });

  final String patientId;

  @override
  ConsumerState<DoctorPrescriptionAuthoringPage> createState() =>
      _DoctorPrescriptionAuthoringPageState();
}

class _DoctorPrescriptionAuthoringPageState
    extends ConsumerState<DoctorPrescriptionAuthoringPage> {
  final _nameCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _urgentReasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Gender _gender = Gender.male; // ignore: prefer_final_fields
  int _age = 30; // ignore: prefer_final_fields
  bool _isUrgent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _urgentReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final doctorId = Supabase.instance.client.auth.currentUser?.id;
    if (doctorId == null) return;

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
          patientId: widget.patientId,
          patientName: _nameCtrl.text.trim(),
          patientGender: _gender,
          patientAge: _age,
          symptoms: _symptomsCtrl.text.trim(),
          diagnosis: _diagnosisCtrl.text.trim().isEmpty
              ? null
              : _diagnosisCtrl.text.trim(),
          doctorId: doctorId,
          medications: const <Map<String, dynamic>>[],
          patientTimezone: 'Asia/Phnom_Penh',
          isUrgent: _isUrgent,
          urgentReason: _isUrgent && _urgentReasonCtrl.text.trim().isNotEmpty
              ? _urgentReasonCtrl.text.trim()
              : null,
        ),
      );
      if (mounted) {
        ref.invalidate(prescriptionsByPatientProvider(widget.patientId));
        context.go('/patient/prescriptions/${p.id}');
      }
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
                label: 'Diagnosis',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Urgent (auto-apply)'),
                subtitle: const Text(
                  'Prescription activates immediately without patient confirmation.',
                ),
                value: _isUrgent,
                onChanged: (v) => setState(() => _isUrgent = v),
              ),
              if (_isUrgent) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _urgentReasonCtrl,
                  label: 'Reason for urgent change',
                  maxLines: 2,
                  validator: (v) => _isUrgent && (v == null || v.trim().isEmpty)
                      ? 'Required for urgent prescriptions'
                      : null,
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l.savePrescription,
                onPressed: _loading ? null : _submit,
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
