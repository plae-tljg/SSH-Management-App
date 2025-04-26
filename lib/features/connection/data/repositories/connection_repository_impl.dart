import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/connection_config.dart';
import '../../domain/repositories/connection_repository.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  static const String _storageKey = 'ssh_connections';
  final SharedPreferences _prefs;

  ConnectionRepositoryImpl(this._prefs);

  @override
  Future<List<ConnectionConfig>> getAllConnections() async {
    final String? connectionsJson = _prefs.getString(_storageKey);
    if (connectionsJson == null) return [];

    final List<dynamic> connectionsList = json.decode(connectionsJson);
    return connectionsList
        .map((json) => ConnectionConfig.fromJson(json))
        .toList();
  }

  @override
  Future<ConnectionConfig?> getConnectionById(String id) async {
    final connections = await getAllConnections();
    return connections.firstWhere(
      (connection) => connection.id == id,
      orElse: () => throw Exception('Connection not found'),
    );
  }

  @override
  Future<void> saveConnection(ConnectionConfig connection) async {
    final connections = await getAllConnections();
    connections.add(connection);
    await _saveConnections(connections);
  }

  @override
  Future<void> deleteConnection(String id) async {
    final connections = await getAllConnections();
    connections.removeWhere((connection) => connection.id == id);
    await _saveConnections(connections);
  }

  @override
  Future<void> updateConnection(ConnectionConfig connection) async {
    final connections = await getAllConnections();
    final index = connections.indexWhere((c) => c.id == connection.id);
    if (index != -1) {
      connections[index] = connection;
      await _saveConnections(connections);
    }
  }

  Future<void> _saveConnections(List<ConnectionConfig> connections) async {
    final connectionsJson = json.encode(
      connections.map((connection) => connection.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, connectionsJson);
  }
} 