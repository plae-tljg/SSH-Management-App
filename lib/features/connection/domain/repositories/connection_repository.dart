import '../entities/connection_config.dart';

abstract class ConnectionRepository {
  Future<List<ConnectionConfig>> getAllConnections();
  Future<ConnectionConfig?> getConnectionById(String id);
  Future<void> saveConnection(ConnectionConfig connection);
  Future<void> deleteConnection(String id);
  Future<void> updateConnection(ConnectionConfig connection);
} 