import 'package:das_tern/data/models/connection.dart';
import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/services/connection_service.dart';

abstract class ConnectionRepository {
  Future<List<Connection>> getConnections();
  Future<ConnectionToken> generateToken(PermissionLevel permissionLevel);
  Future<Connection> consumeToken(String token);
  Future<void> revokeConnection(String id);
}

class ConnectionRepositoryImpl implements ConnectionRepository {
  ConnectionRepositoryImpl({required ConnectionService service})
    : _service = service;

  final ConnectionService _service;

  @override
  Future<List<Connection>> getConnections() => _service.fetchConnections();

  @override
  Future<ConnectionToken> generateToken(PermissionLevel permissionLevel) =>
      _service.generateToken(permissionLevel);

  @override
  Future<Connection> consumeToken(String token) => _service.consumeToken(token);

  @override
  Future<void> revokeConnection(String id) => _service.revokeConnection(id);
}
