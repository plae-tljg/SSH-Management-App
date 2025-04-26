import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../../domain/entities/terminal_session.dart';
import '../../domain/repositories/terminal_repository.dart';
import '../../../connection/domain/entities/connection_config.dart';

class TerminalRepositoryImpl implements TerminalRepository {
  final Map<String, SSHClient> _clients = {};
  final Map<String, SSHSession> _sessions = {};
  final Map<String, StreamController<String>> _outputControllers = {};

  @override
  Future<TerminalSession> createSession(ConnectionConfig connection) async {
    try {
      final client = await _createSSHClient(connection);
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = await client.shell();
      
      _clients[sessionId] = client;
      _sessions[sessionId] = session;
      _outputControllers[sessionId] = StreamController<String>.broadcast();

      // 设置终端环境
      final envCommands = [
        'export TERM=xterm-256color',
        'export LANG=en_US.UTF-8',
        'export LC_ALL=en_US.UTF-8',
        'export PYTHONIOENCODING=utf-8',
        'export CLICOLOR=1',
        'export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd',
        'stty -echo -icanon min 1 time 0',
        'set +o history'  // 禁用命令历史
      ];

      // 每个命令单独执行，确保正确换行
      for (final cmd in envCommands) {
        session.write(utf8.encode('$cmd > /dev/null 2>&1\n'));
      }

      // 开始监听会话输出
      session.stdout.listen((data) {
        final output = utf8.decode(data);
        // 处理 ANSI 转义序列和乱码
        final cleanOutput = output
            .replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '')  // 普通 ANSI 序列
            .replaceAll(RegExp(r'\x1B\[\?[0-9;]*[a-zA-Z]'), '')  // DEC 私有模式
            .replaceAll(RegExp(r'\x1B\]0;.*?\x07'), '')  // OSC 0 序列（窗口标题）
            .replaceAll(RegExp(r'\x1B\][0-9;]*\x07'), '')  // 其他 OSC 序列
            .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')  // 控制字符
            .replaceAll(RegExp(r'export.*\n'), '')  // 移除 export 命令回显
            .replaceAll(RegExp(r'stty.*\n'), '')  // 移除 stty 命令回显
            .replaceAll(RegExp(r'set.*\n'), '')  // 移除 set 命令回显
            .replaceAll(RegExp(r'\n+'), '\n');  // 多个换行符替换为单个
        
        if (!cleanOutput.endsWith('\n')) {
          _outputControllers[sessionId]?.add(cleanOutput + '\n');
        } else {
          _outputControllers[sessionId]?.add(cleanOutput);
        }
      });

      session.stderr.listen((data) {
        final output = utf8.decode(data);
        // 处理 ANSI 转义序列和乱码
        final cleanOutput = output
            .replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '')  // 普通 ANSI 序列
            .replaceAll(RegExp(r'\x1B\[\?[0-9;]*[a-zA-Z]'), '')  // DEC 私有模式
            .replaceAll(RegExp(r'\x1B\]0;.*?\x07'), '')  // OSC 0 序列（窗口标题）
            .replaceAll(RegExp(r'\x1B\][0-9;]*\x07'), '')  // 其他 OSC 序列
            .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')  // 控制字符
            .replaceAll(RegExp(r'export.*\n'), '')  // 移除 export 命令回显
            .replaceAll(RegExp(r'stty.*\n'), '')  // 移除 stty 命令回显
            .replaceAll(RegExp(r'set.*\n'), '')  // 移除 set 命令回显
            .replaceAll(RegExp(r'\n+'), '\n');  // 多个换行符替换为单个
        
        if (!cleanOutput.endsWith('\n')) {
          _outputControllers[sessionId]?.add(cleanOutput + '\n');
        } else {
          _outputControllers[sessionId]?.add(cleanOutput);
        }
      });

      return TerminalSession(
        id: sessionId,
        connection: connection,
        startTime: DateTime.now(),
        isConnected: true,
      );
    } catch (e) {
      return TerminalSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        connection: connection,
        startTime: DateTime.now(),
        isConnected: false,
        lastError: e.toString(),
      );
    }
  }

  @override
  Future<void> closeSession(String sessionId) async {
    final session = _sessions[sessionId];
    if (session != null) {
      session.close();
      _sessions.remove(sessionId);
    }

    final client = _clients[sessionId];
    if (client != null) {
      client.close();
      _clients.remove(sessionId);
    }

    final controller = _outputControllers[sessionId];
    if (controller != null) {
      await controller.close();
      _outputControllers.remove(sessionId);
    }
  }

  @override
  Future<void> executeCommand(String sessionId, String command) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw Exception('Session not found');
    }

    try {
      session.write(utf8.encode(command + '\n'));
    } catch (e) {
      _outputControllers[sessionId]?.add('Error: $e');
    }
  }

  @override
  Stream<String> getCommandOutput(String sessionId) {
    return _outputControllers[sessionId]?.stream ?? Stream.empty();
  }

  @override
  Future<bool> isConnected(String sessionId) async {
    return _sessions.containsKey(sessionId);
  }

  Future<SSHClient> _createSSHClient(ConnectionConfig connection) async {
    try {
      final socket = await SSHSocket.connect(
        connection.host,
        connection.port,
        timeout: const Duration(seconds: 10),
      );

      final client = SSHClient(
        socket,
        username: connection.username,
        onPasswordRequest: () => connection.password ?? '',
      );

      await client.authenticated;
      return client;
    } catch (e) {
      print('SSH连接错误: $e');
      rethrow;
    }
  }
} 