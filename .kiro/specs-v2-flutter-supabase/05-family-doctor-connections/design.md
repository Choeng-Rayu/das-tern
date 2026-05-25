# Design: Connections (Patient↔Patient and Doctor↔Patient)

> **Updated by ADDENDUM-001 (2026-05-25):** QR scan only, role-aware QR, mutual peer-Patient model, no doctor search.

## 1. Module structure

```
lib/features/connections/
├── data/
│   ├── connection_repository.dart
│   ├── connection_token_repository.dart
│   └── peer_alert_repository.dart       # send check-in / nudge to a peer
├── domain/
│   ├── connection.dart                  # freezed
│   ├── connection_kind.dart             # peer | clinical
│   ├── connection_token.dart
│   ├── permission_level.dart
│   └── usecases/
│       ├── generate_connect_qr.dart
│       ├── consume_qr_token.dart
│       ├── accept_connection.dart
│       ├── mute_peer_connection.dart
│       ├── revoke_connection.dart
│       ├── change_doctor_permission.dart
│       └── send_peer_check_in.dart
└── presentation/
    ├── pages/
    │   ├── my_connections_page.dart            # two-section list
    │   ├── show_qr_page.dart                   # generator side
    │   ├── scan_qr_page.dart                   # scanner side
    │   ├── connection_detail_page.dart
    │   ├── peer_overview_page.dart             # read-only peer's adherence
    │   ├── pending_request_sheet.dart
    │   └── connection_history_page.dart
    └── widgets/
        ├── peer_connection_card.dart
        ├── doctor_connection_card.dart
        ├── permission_chip.dart
        ├── mute_toggle.dart
        └── role_badge.dart
```

## 2. QR generation (any role)

```dart
class GenerateConnectQrUseCase {
  GenerateConnectQrUseCase(this._supabase);
  final SupabaseClient _supabase;

  Future<ConnectionToken> call() async {
    final me = await _supabase.from('profiles')
        .select('id, role').eq('id', _supabase.auth.currentUser!.id).single();
    final shortCode = _generateShortCode();

    final row = await _supabase.from('connection_tokens').insert({
      'patient_id': me['id'],            // historical column name; this is the GENERATOR's id
      'token': shortCode,
      'permission_level': 'ALLOWED',
      'intended_role': me['role'],       // 'PATIENT' or 'DOCTOR'
      'expires_at': DateTime.now().toUtc()
          .add(const Duration(hours: 1)).toIso8601String(),
    }).select().single();

    return ConnectionToken.fromJson(row);
  }

  String _generateShortCode() {
    const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rng = Random.secure();
    return List.generate(10, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
  }
}
```

> The `connection_tokens.patient_id` column is named historically. We keep the column name to avoid a renamed migration; the Drift mirror and code refer to it as `generator_id` semantically. A view `connection_tokens_v` exposes it under both names if needed.

```dart
class ShowQrPage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProfileProvider).value;
    final tokenAsync = ref.watch(currentConnectTokenProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.showQrTitle)),
      body: Center(child: tokenAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (t) {
          final deepLink =
              'dastern://connect?token=${t.token}&role=${me!.role.code}&v=1';
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${me.fullName ?? '—'}',
                 style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            RoleBadge(role: me.role),
            const SizedBox(height: 24),
            QrImageView(
              data: deepLink,
              size: 280,
              errorCorrectionLevel: QrErrorCorrectLevel.Q,
            ),
            const SizedBox(height: 8),
            ExpiryCountdown(expiresAt: t.expiresAt),
            const SizedBox(height: 16),
            AppButton(
              label: AppLocalizations.of(context)!.regenerateCode,
              variant: AppButtonVariant.outlined,
              onPressed: () =>
                  ref.invalidate(currentConnectTokenProvider),
            ),
          ]);
        },
      )),
    );
  }
}
```

## 3. QR scan

```dart
class ScanQrPage extends ConsumerStatefulWidget {...}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  bool _consuming = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_consuming) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'dastern' || uri.host != 'connect') {
      _showError('not_a_dastern_qr');
      return;
    }
    final token = uri.queryParameters['token'];
    if (token == null || token.length < 8) {
      _showError('invalid_qr');
      return;
    }

    setState(() => _consuming = true);
    try {
      final connectionId = await ref.read(consumeQrTokenProvider).call(token);
      // Routes to "Waiting for approval" page
      if (mounted) {
        context.replace('/connections/waiting/$connectionId');
      }
    } on ConnectionFailure catch (e) {
      _showError(e.code);
    } finally {
      if (mounted) setState(() => _consuming = false);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.scanQrTitle)),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        const _FrameOverlay(),
        if (_consuming) const Positioned.fill(
          child: ColoredBox(color: Colors.black54,
            child: Center(child: CircularProgressIndicator())),
        ),
      ]),
    );
  }
}
```

```dart
class ConsumeQrTokenUseCase {
  Future<String> call(String code) async {
    try {
      final id = await _supabase.rpc('consume_connection_token',
          params: {'p_token': code});
      return id as String;
    } on PostgrestException catch (e) {
      throw ConnectionFailure.fromMessage(e.message);
    }
  }
}
```

The SQL function `consume_connection_token` (already defined in `01-supabase-data-layer/design.md`, with one update below) returns the new connection id and rejects:
- Doctor scanning a Doctor's QR (role conflict).
- Self-scan.
- Expired or used tokens.

```sql
-- Updated consume_connection_token: rejects Doctor↔Doctor
create or replace function public.consume_connection_token(p_token text)
returns uuid language plpgsql security definer as $$
declare
  v_token  public.connection_tokens;
  v_me_role user_role;
  v_gen_role user_role;
  v_connection_id uuid;
begin
  select * into v_token from public.connection_tokens
   where token = p_token for update;
  if not found then raise exception 'token_not_found' using errcode = 'P0002'; end if;
  if v_token.expires_at < now() then raise exception 'token_expired'; end if;
  if v_token.used_at is not null then raise exception 'token_already_used'; end if;
  if v_token.patient_id = auth.uid() then raise exception 'self_connection_not_allowed'; end if;

  select role into v_me_role  from public.profiles where id = auth.uid();
  select role into v_gen_role from public.profiles where id = v_token.patient_id;
  if v_me_role = 'DOCTOR' and v_gen_role = 'DOCTOR' then
    raise exception 'doctor_to_doctor_not_allowed';
  end if;

  update public.connection_tokens
     set used_at = now(), used_by_id = auth.uid()
   where id = v_token.id;

  insert into public.connections (initiator_id, recipient_id, permission_level, status)
  values (auth.uid(), v_token.patient_id, v_token.permission_level, 'PENDING')
  on conflict (initiator_id, recipient_id) do update set status = 'PENDING'
  returning id into v_connection_id;

  insert into public.audit_logs (actor_id, action_type, resource_type, resource_id, details)
  values (auth.uid(), 'CONNECTION_REQUEST', 'connections', v_connection_id,
          jsonb_build_object('token_id', v_token.id,
                             'generator_role', v_gen_role,
                             'scanner_role', v_me_role));
  return v_connection_id;
end;
$$;
```

## 4. Approval

```dart
class AcceptConnectionUseCase {
  Future<void> call(String connectionId, {PermissionLevel? permission}) async {
    await _supabase.rpc('accept_connection', params: {
      'p_connection_id': connectionId,
      'p_permission': permission?.code,
    });
  }
}
```

The Postgres function (defined earlier) sets `status = 'ACCEPTED'`, applies the optional permission level, writes the audit log. For peer-Patient connections we always pass `permission = 'ALLOWED'`.

The approval sheet adapts to the relationship kind:

```dart
Widget build(...) {
  final isPeer = otherProfile.role == UserRole.patient;
  return Sheet(child: Column(children: [
    if (isPeer) Text(l10n.peerApprovalDescription)
    else Text(l10n.clinicalApprovalDescription),
    if (!isPeer) PermissionPicker(value: _permission,
                                  onChanged: (v) => setState(() => _permission = v)),
    Row(children: [
      AppButton(label: l10n.reject, variant: AppButtonVariant.outlined,
                onPressed: _reject),
      AppButton(label: l10n.accept, onPressed: _accept),
    ]),
  ]));
}
```

## 5. RLS policies for peer-Patient mutual access

The existing RLS on `prescriptions`, `medications`, `dose_events` already allows reads when `is_connected_with(other)` returns true. We add a clarifying helper specific to peers:

```sql
-- Replaces is_connected_family_for
create or replace function public.is_connected_peer_patient_for(p_patient_id uuid)
returns boolean language sql stable as $$
  select exists (
    select 1
    from public.connections c
    join public.profiles me on me.id = auth.uid()
    join public.profiles other on other.id = p_patient_id
    where c.status = 'ACCEPTED'
      and me.role = 'PATIENT'
      and other.role = 'PATIENT'
      and c.permission_level <> 'NOT_ALLOWED'
      and (
        (c.initiator_id = auth.uid() and c.recipient_id = p_patient_id)
        or (c.recipient_id = auth.uid() and c.initiator_id = p_patient_id)
      )
  );
$$;
```

The existing prescription/medication/dose_event policies that referred to `is_connected_family_for` are renamed to call `is_connected_peer_patient_for`. Doctor policies are unchanged (`is_connected_doctor_for`).

## 6. Mutual missed-dose alert trigger

The `tg_dose_status_change` trigger from `04-reminder-adherence/design.md` is updated to use the new helper logic. Rather than filtering by FAMILY_MEMBER role, it filters by "the other side of an ACCEPTED peer-Patient connection":

```sql
create or replace function public.tg_dose_status_change()
returns trigger language plpgsql security definer as $$
begin
  if (new.status = 'MISSED' and old.status = 'DUE') then
    -- 1. Patient self-notification
    insert into public.notifications (recipient_id, type, title, message, data)
    values (new.patient_id, 'MISSED_DOSE_ALERT',
            'Dose missed', 'You missed a scheduled dose. Tap to mark as taken or skip.',
            jsonb_build_object('dose_event_id', new.id, 'medication_id', new.medication_id));

    -- 2. Mutual peer-patient alerts
    insert into public.notifications (recipient_id, type, title, message, data)
    select case
             when c.initiator_id = new.patient_id then c.recipient_id
             else c.initiator_id end,
           'FAMILY_ALERT',
           'A connected person missed a dose',
           coalesce((select first_name from public.profiles where id = new.patient_id), 'Someone')
             || ' missed a dose',
           jsonb_build_object('dose_event_id', new.id, 'patient_id', new.patient_id)
      from public.connections c
     where c.status = 'ACCEPTED'
       and (c.initiator_id = new.patient_id or c.recipient_id = new.patient_id)
       and c.permission_level <> 'NOT_ALLOWED'
       -- both endpoints must be PATIENTs to count as a peer connection
       and exists (select 1 from public.profiles p
                    where p.id = case
                            when c.initiator_id = new.patient_id then c.recipient_id
                            else c.initiator_id end
                      and p.role = 'PATIENT')
       and exists (select 1 from public.profiles p
                    where p.id = new.patient_id and p.role = 'PATIENT');
  end if;

  if (new.status in ('TAKEN_ON_TIME','TAKEN_LATE') and old.status = 'MISSED') then
    insert into public.notifications (recipient_id, type, title, message, data)
    select case
             when c.initiator_id = new.patient_id then c.recipient_id
             else c.initiator_id end,
           'DOSE_CONFIRMED',
           'Patient took the missed dose',
           'A peer marked the missed dose as taken.',
           jsonb_build_object('dose_event_id', new.id)
      from public.connections c
     where c.status = 'ACCEPTED'
       and (c.initiator_id = new.patient_id or c.recipient_id = new.patient_id)
       and c.permission_level <> 'NOT_ALLOWED'
       and exists (select 1 from public.profiles p
                    where p.id = case
                            when c.initiator_id = new.patient_id then c.recipient_id
                            else c.initiator_id end
                      and p.role = 'PATIENT');
  end if;
  return new;
end;
$$;
```

This trigger is registered on `dose_events` exactly as before; only the body changed.

## 7. Mute / pause peer connection

```dart
class MutePeerConnectionUseCase {
  Future<void> call(String connectionId, {required bool muted}) async {
    await _supabase.from('connections').update({
      'permission_level': muted ? 'NOT_ALLOWED' : 'ALLOWED',
    }).eq('id', connectionId);
    await _supabase.rpc('create_audit_log', params: {
      'p_action': 'PERMISSION_CHANGE',
      'p_resource_type': 'connections',
      'p_resource_id': connectionId,
      'p_details': {'muted': muted}.jsonify(),
    });
  }
}
```

## 8. Doctor-permission management

For Doctor↔Patient connections, the patient still picks among the four levels. The Flutter UI exposes a `PermissionPicker` chip group on the connection detail page, calling `change_doctor_permission` use case which performs the same `UPDATE`.

## 9. Connections home

```dart
class MyConnectionsPage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProfileProvider).value;
    final connections = ref.watch(myConnectionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.myConnections)),
      floatingActionButton: SpeedDial(actions: [
        SpeedDialAction(icon: Icons.qr_code_2, label: 'Show QR',
            onTap: () => context.push('/connections/show')),
        SpeedDialAction(icon: Icons.qr_code_scanner, label: 'Scan QR',
            onTap: () => context.push('/connections/scan')),
      ]),
      body: connections.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (cs) {
          final peers = cs.where((c) => c.kind == ConnectionKind.peer).toList();
          final docs  = cs.where((c) => c.kind == ConnectionKind.clinical).toList();
          return ListView(children: [
            if (me?.role == UserRole.patient) ...[
              SectionHeader(title: 'My peers',
                  trailing: Text('${peers.length} / ${ref.watch(featuresProvider).caregiverLimit}')),
              for (final c in peers) PeerConnectionCard(connection: c),
              const SectionHeader(title: 'Healthcare providers'),
              for (final c in docs) DoctorConnectionCard(connection: c),
            ] else ...[
              const SectionHeader(title: 'My patients'),
              for (final c in docs) DoctorPatientCard(connection: c),
            ],
          ]);
        },
      ),
    );
  }
}
```

## 10. Peer overview (read-only)

```dart
class PeerOverviewPage extends ConsumerWidget {
  const PeerOverviewPage({super.key, required this.peerUserId});
  final String peerUserId;

  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(peerTodayDosesProvider(peerUserId));
    final adherence = ref.watch(peerAdherenceProvider(peerUserId));
    return Scaffold(
      appBar: AppBar(),
      body: Column(children: [
        const _ReadOnlyBanner(),
        AdherenceRing(percent: adherence.valueOrNull?.percent ?? 0),
        Expanded(child: today.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: e.toString()),
          data: (events) => ListView(
            children: events.map((e) => DoseRow(event: e, readOnly: true)).toList(),
          ),
        )),
        if (_anyMissed(today.valueOrNull)) Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            label: 'Send check-in',
            onPressed: () => ref.read(sendPeerCheckInProvider).call(peerUserId),
          ),
        ),
      ]),
    );
  }
}
```

## 11. Peer check-in (replaces the v1 "nudge" feature)

```dart
class SendPeerCheckInUseCase {
  Future<void> call(String peerUserId, {String? doseEventId}) async {
    final count = await _supabase.from('audit_logs')
      .select('id')
      .eq('actor_id', _supabase.auth.currentUser!.id)
      .eq('action_type', 'NOTIFICATION_SENT')
      .filter('details->>kind', 'eq', 'peer_check_in')
      .filter('details->>peer_id', 'eq', peerUserId)
      .gte('created_at', DateTime.now().subtract(const Duration(hours: 24)).toIso8601String())
      .count();
    if (count.count >= 5) throw const PeerCheckInFailure.rateLimited();

    await _supabase.rpc('create_notification', params: {
      'p_recipient_id': peerUserId,
      'p_type': 'FAMILY_ALERT',
      'p_title': 'A connected friend is checking on you',
      'p_message': 'They want to make sure you took your medicine.',
      'p_data': {'sent_by': _supabase.auth.currentUser!.id,
                 if (doseEventId != null) 'dose_event_id': doseEventId}.jsonify(),
    });
    await _supabase.rpc('create_audit_log', params: {
      'p_action': 'NOTIFICATION_SENT',
      'p_resource_type': 'profiles',
      'p_resource_id': peerUserId,
      'p_details': {'kind': 'peer_check_in', 'peer_id': peerUserId}.jsonify(),
    });
  }
}
```

## 12. Connection-limit trigger updated

```sql
create or replace function public.check_connection_limits()
returns trigger language plpgsql as $$
declare
  v_tier subscription_tier;
  v_count integer;
  v_limit integer;
  v_patient_id uuid;
  v_other_role user_role;
begin
  if new.status <> 'ACCEPTED' then return new; end if;

  -- We only enforce the limit on PEER (Patient↔Patient) connections.
  select role into v_other_role from public.profiles
   where id = case when new.initiator_id = auth.uid() then new.recipient_id else new.initiator_id end;
  if v_other_role <> 'PATIENT' then return new; end if;

  -- The "owning" patient for tier lookup is the user being limited.
  -- Both sides count this connection toward their own tier.
  for v_patient_id in select unnest(array[new.initiator_id, new.recipient_id]) loop
    select tier into v_tier from public.subscriptions where user_id = v_patient_id;
    v_limit := case coalesce(v_tier, 'FREEMIUM')
                 when 'FREEMIUM' then 1
                 when 'PREMIUM' then 5
                 when 'FAMILY_PREMIUM' then 10 end;
    select count(*) into v_count
      from public.connections c
      where c.status = 'ACCEPTED'
        and (c.initiator_id = v_patient_id or c.recipient_id = v_patient_id)
        and c.id <> new.id
        and exists (
          select 1 from public.profiles p
          where p.id = case when c.initiator_id = v_patient_id then c.recipient_id else c.initiator_id end
            and p.role = 'PATIENT');
    if v_count >= v_limit then
      raise exception 'connection_limit_reached: tier=%, limit=%, user=%', v_tier, v_limit, v_patient_id;
    end if;
  end loop;
  return new;
end;
$$;
```

## 13. Realtime invalidation

The previous `ConnectionRealtimeListener` (in the original draft of this design) is unchanged in shape. The events it reacts to now include any peer-Patient permission change for both sides.

## 14. Doctor side (no search)

Doctors find patients exclusively via QR scan (or by patient-initiated request when a patient scans the doctor's QR). The doctor dashboard in `06-doctor-dashboard` lists only patients with ACCEPTED clinical connections.

## 15. Testing

- Unit: `consume_connection_token` rejects doctor-to-doctor; accepts patient-to-doctor and patient-to-patient.
- Unit: `MutePeerConnectionUseCase` toggles permission and writes audit.
- Widget: My Connections page renders peer + clinical sections correctly per role.
- Integration: two devices simulate scan → approve → both sides see counterparty data; mute → both lose visibility.
- pgtap: mutual peer alert trigger emits exactly one notification per peer per missed dose (no duplicates).
