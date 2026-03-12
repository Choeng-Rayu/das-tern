import 'dart:async';

import 'package:das_tern/data/models/connection.dart';
import 'package:das_tern/data/models/enums.dart';

abstract class ConnectionService {
  Future<List<Connection>> fetchConnections();
  Future<ConnectionToken> generateToken(PermissionLevel permissionLevel);
  Future<Connection> consumeToken(String token);
  Future<void> revokeConnection(String id);
}

class MockConnectionService implements ConnectionService {
  final List<Connection> _connections = [];

  @override
  Future<List<Connection>> fetchConnections() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<Connection>.unmodifiable(_connections);
  }

  @override
  Future<ConnectionToken> generateToken(PermissionLevel permissionLevel) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ConnectionToken(
      id: 'token-${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'user-1',
      token: '123456',
      permissionLevel: permissionLevel,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<Connection> consumeToken(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final connection = Connection(
      id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
      initiatorId: 'user-1',
      recipientId: 'user-2',
      status: ConnectionStatus.accepted,
      permissionLevel: PermissionLevel.allowed,
      createdAt: DateTime.now(),
      recipientName: 'Sok Lina',
    );
    _connections.add(connection);
    return connection;
  }

  @override
  Future<void> revokeConnection(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _connections.removeWhere((c) => c.id == id);
  }
}
