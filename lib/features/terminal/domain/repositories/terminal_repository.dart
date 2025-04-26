import '../entities/terminal_session.dart';
import '../../../connection/domain/entities/connection_config.dart';

abstract class TerminalRepository {
  Future<TerminalSession> createSession(ConnectionConfig connection);
  Future<void> closeSession(String sessionId);
  Future<void> executeCommand(String sessionId, String command);
  Stream<String> getCommandOutput(String sessionId);
  Future<bool> isConnected(String sessionId);
} 