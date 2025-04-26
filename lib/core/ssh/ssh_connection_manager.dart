import 'package:dartssh2/dartssh2.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../features/connection/domain/entities/connection_config.dart';

class SSHConnectionManager {
  static final SSHConnectionManager _instance = SSHConnectionManager._internal();
  factory SSHConnectionManager() => _instance;
  SSHConnectionManager._internal() {
    _setupLifecycleListener();
  }

  final Map<String, SSHClient> _clients = {};
  final Map<String, Timer> _keepAliveTimers = {};
  final Map<String, bool> _isFilePickerOpen = {};
  bool _isAppInBackground = false;

  void _setupLifecycleListener() {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.paused.toString()) {
        _isAppInBackground = true;
        print('应用进入后台，暂停keep-alive');
        _pauseAllKeepAliveTimers();
      } else if (msg == AppLifecycleState.resumed.toString()) {
        _isAppInBackground = false;
        print('应用回到前台，恢复keep-alive');
        _resumeAllKeepAliveTimers();
      }
      return null;
    });
  }

  void _pauseAllKeepAliveTimers() {
    for (final timer in _keepAliveTimers.values) {
      timer.cancel();
    }
  }

  void _resumeAllKeepAliveTimers() {
    for (final key in _clients.keys) {
      _startKeepAliveTimer(key);
    }
  }

  Future<SSHClient> getClient(ConnectionConfig connection) async {
    final key = connection.id;
    
    if (_clients.containsKey(key) && await _isConnectionAlive(_clients[key]!)) {
      return _clients[key]!;
    }

    final client = await _createSSHClient(connection);
    _clients[key] = client;
    if (!_isAppInBackground) {
      _startKeepAliveTimer(key);
    }
    return client;
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
        keepAliveInterval: const Duration(seconds: 30),
      );

      await client.authenticated;
      return client;
    } catch (e) {
      print('SSH连接错误: $e');
      rethrow;
    }
  }

  Future<bool> _isConnectionAlive(SSHClient client) async {
    try {
      await client.execute('echo "test"');
      return true;
    } catch (e) {
      print('连接检查失败: $e');
      return false;
    }
  }

  void _startKeepAliveTimer(String key) {
    if (_isAppInBackground) return;
    
    _keepAliveTimers[key]?.cancel();
    _keepAliveTimers[key] = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_isFilePickerOpen[key] != true && !_isAppInBackground) {
        try {
          final client = _clients[key];
          if (client != null) {
            await client.execute('echo "keepalive"');
          }
        } catch (e) {
          print('Keep-alive失败: $e');
          _clients.remove(key);
          _keepAliveTimers[key]?.cancel();
          _keepAliveTimers.remove(key);
        }
      }
    });
  }

  void setFilePickerOpen(String key, bool isOpen) {
    _isFilePickerOpen[key] = isOpen;
  }

  void closeConnection(String key) {
    _clients[key]?.close();
    _clients.remove(key);
    _keepAliveTimers[key]?.cancel();
    _keepAliveTimers.remove(key);
    _isFilePickerOpen.remove(key);
  }

  void dispose() {
    for (final client in _clients.values) {
      client.close();
    }
    _clients.clear();
    for (final timer in _keepAliveTimers.values) {
      timer.cancel();
    }
    _keepAliveTimers.clear();
    _isFilePickerOpen.clear();
  }
} 