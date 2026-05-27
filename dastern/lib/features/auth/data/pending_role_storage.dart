import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/chosen_role.dart';

/// Persists the role chosen at WelcomePage across the OAuth round-trip.
/// Cleared after first-bootstrap consumption.
class PendingRoleStorage {
  const PendingRoleStorage(this._secure);
  final FlutterSecureStorage _secure;

  static const _key = 'pending_role_v1';

  Future<void> set(ChosenRole role) =>
      _secure.write(key: _key, value: role.code);

  Future<ChosenRole?> read() async {
    final v = await _secure.read(key: _key);
    return ChosenRole.fromCode(v);
  }

  Future<void> clear() => _secure.delete(key: _key);
}
