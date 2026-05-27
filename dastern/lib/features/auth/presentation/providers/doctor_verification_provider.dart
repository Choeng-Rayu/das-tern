import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';

/// True when the doctor with [doctorId] has `account_status = 'VERIFIED'`.
///
/// Spec ref: 02-authentication §8.7.
final AutoDisposeFutureProviderFamily<bool, String> isDoctorVerifiedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, doctorId) async {
  final row = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select('account_status')
      .eq('id', doctorId)
      .maybeSingle();
  return row?['account_status'] == 'VERIFIED';
});
