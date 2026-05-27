import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_session_storage.dart';
import '../../data/google_auth_client.dart';
import '../../data/pending_role_storage.dart';
import '../../data/telegram_auth_client.dart';
import '../../domain/chosen_role.dart';

// ── Storage helpers ───────────────────────────────────────────────────

final Provider<FlutterSecureStorage> flutterSecureStorageProvider =
    Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage());

final Provider<PendingRoleStorage> pendingRoleStorageProvider =
    Provider<PendingRoleStorage>(
  (ref) => PendingRoleStorage(ref.watch(flutterSecureStorageProvider)),
);

final Provider<AuthSessionStorage> authSessionStorageProvider =
    Provider<AuthSessionStorage>(
  (ref) => AuthSessionStorage(ref.watch(flutterSecureStorageProvider)),
);

// ── Auth clients ──────────────────────────────────────────────────────

final Provider<GoogleAuthClient> googleAuthClientProvider =
    Provider<GoogleAuthClient>((_) => GoogleAuthClient());

final Provider<TelegramAuthClient> telegramAuthClientProvider =
    Provider<TelegramAuthClient>(
  (ref) => TelegramAuthClient(
    ref.watch(supabaseClientProvider),
    ref.watch(flutterSecureStorageProvider),
  ),
);

// ── Repository ────────────────────────────────────────────────────────

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
  (ref) => AuthRepository(
    supabase: ref.watch(supabaseClientProvider),
    sessionStorage: ref.watch(authSessionStorageProvider),
    google: ref.watch(googleAuthClientProvider),
    telegram: ref.watch(telegramAuthClientProvider),
    pendingRole: ref.watch(pendingRoleStorageProvider),
  ),
);

// ── Auth state stream ─────────────────────────────────────────────────

final StreamProvider<AuthState> authStateProvider =
    StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

// ── Current user profile ──────────────────────────────────────────────

final FutureProvider<Map<String, dynamic>?> currentUserProfileProvider =
    FutureProvider<Map<String, dynamic>?>(
  (ref) async {
    final state = ref.watch(authStateProvider).valueOrNull;
    final session = state?.session;
    if (session == null) return null;
    return Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', session.user.id)
        .maybeSingle();
  },
);

// ── Pending role controller ───────────────────────────────────────────

class PendingRoleController extends StateNotifier<ChosenRole?> {
  PendingRoleController(this._storage) : super(null) {
    _storage.read().then((v) => state = v);
  }
  final PendingRoleStorage _storage;

  Future<void> set(ChosenRole role) async {
    await _storage.set(role);
    state = role;
  }

  Future<void> clear() async {
    await _storage.clear();
    state = null;
  }
}

final StateNotifierProvider<PendingRoleController, ChosenRole?>
    pendingRoleProvider =
    StateNotifierProvider<PendingRoleController, ChosenRole?>(
  (ref) => PendingRoleController(ref.watch(pendingRoleStorageProvider)),
);

// ── Role-aware initial route ──────────────────────────────────────────

final Provider<String> roleAwareInitialRouteProvider = Provider<String>(
  (ref) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    if (authState?.session == null) return '/welcome';
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile == null) return '/welcome';
    final firstName = profile['first_name'] as String?;
    if (firstName == null || firstName.isEmpty) return '/profile-bootstrap';
    final role = profile['role'] as String?;
    return role == 'DOCTOR' ? '/doctor/home' : '/patient/home';
  },
);
