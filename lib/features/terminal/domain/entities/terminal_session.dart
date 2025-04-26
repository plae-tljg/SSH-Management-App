import '../../../connection/domain/entities/connection_config.dart';

class TerminalSession {
  final String id;
  final ConnectionConfig connection;
  final DateTime startTime;
  final bool isConnected;
  final String? lastError;

  TerminalSession({
    required this.id,
    required this.connection,
    required this.startTime,
    this.isConnected = false,
    this.lastError,
  });

  TerminalSession copyWith({
    String? id,
    ConnectionConfig? connection,
    DateTime? startTime,
    bool? isConnected,
    String? lastError,
  }) {
    return TerminalSession(
      id: id ?? this.id,
      connection: connection ?? this.connection,
      startTime: startTime ?? this.startTime,
      isConnected: isConnected ?? this.isConnected,
      lastError: lastError ?? this.lastError,
    );
  }
} 