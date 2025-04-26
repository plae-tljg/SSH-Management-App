import 'dart:async';
import '../../domain/entities/terminal_session.dart';
import '../../domain/repositories/terminal_repository.dart';
import '../../../connection/domain/entities/connection_config.dart';

class TerminalController {
  final TerminalRepository _repository;
  TerminalSession? _currentSession;
  final _outputController = StreamController<String>.broadcast();
  final _commandController = StreamController<String>.broadcast();

  TerminalController(this._repository);

  Stream<String> get outputStream => _outputController.stream;
  Stream<String> get commandStream => _commandController.stream;
  TerminalSession? get currentSession => _currentSession;

  Future<void> connect(ConnectionConfig connection) async {
    try {
      _currentSession = await _repository.createSession(connection);
      if (_currentSession!.isConnected) {
        _repository.getCommandOutput(_currentSession!.id).listen((output) {
          _outputController.add(output);
        });
      } else {
        _outputController.add('连接失败: ${_currentSession!.lastError}');
      }
    } catch (e) {
      _outputController.add('连接错误: $e');
    }
  }

  Future<void> disconnect() async {
    if (_currentSession != null) {
      await _repository.closeSession(_currentSession!.id);
      _currentSession = null;
    }
  }

  Future<void> executeCommand(String command) async {
    if (_currentSession == null || !_currentSession!.isConnected) {
      _outputController.add('未连接到服务器');
      return;
    }

    try {
      _commandController.add(command);
      await _repository.executeCommand(_currentSession!.id, command);
    } catch (e) {
      _outputController.add('命令执行错误: $e');
    }
  }

  void dispose() {
    _outputController.close();
    _commandController.close();
  }
} 