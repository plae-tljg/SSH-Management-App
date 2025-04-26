import 'dart:convert';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:dartssh2/dartssh2.dart';
import '../../features/connection/domain/entities/connection_config.dart';

class BackgroundTaskHandler {
  static const String uploadTaskName = 'uploadFile';
  static final BackgroundTaskHandler _instance = BackgroundTaskHandler._internal();
  factory BackgroundTaskHandler() => _instance;
  BackgroundTaskHandler._internal();

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // 配置后台服务
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'ssh_upload_channel',
        initialNotificationTitle: 'SSH上传服务',
        initialNotificationContent: '正在运行',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> scheduleUploadTask({
    required ConnectionConfig connection,
    required String localPath,
    required String remotePath,
  }) async {
    final service = FlutterBackgroundService();
    await service.startService();
    service.invoke('uploadFile', {
      'connection': connection.toJson(),
      'localPath': localPath,
      'remotePath': remotePath,
    });
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('uploadFile').listen((event) async {
      if (event != null) {
        try {
          final connection = ConnectionConfig.fromJson(
            Map<String, dynamic>.from(event['connection']),
          );
          final localPath = event['localPath'] as String;
          final remotePath = event['remotePath'] as String;

          // 检查本地文件是否存在
          final localFile = File(localPath);
          if (!await localFile.exists()) {
            throw Exception('本地文件不存在: $localPath');
          }

          // 检查远程目录权限
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
          
          // 检查远程目录权限
          final dirPath = remotePath.substring(0, remotePath.lastIndexOf('/'));
          if (dirPath.isEmpty) {
            throw Exception('无效的目标路径: $remotePath');
          }

          // 检查目录是否存在
          final checkDirResult = await client.execute('test -d "$dirPath"');
          if (checkDirResult.exitCode != 0) {
            // 目录不存在，尝试创建
            final mkdirResult = await client.execute('mkdir -p "$dirPath"');
            if (mkdirResult.exitCode != 0) {
              throw Exception('无法创建目标目录: $dirPath');
            }
          }

          // 检查目录权限
          final result = await client.execute('test -w "$dirPath"');
          if (result.exitCode != 0) {
            throw Exception('没有写入权限: $dirPath');
          }

          final sftp = await client.sftp();
          final file = await sftp.open(remotePath, mode: SftpFileOpenMode.write | SftpFileOpenMode.create | SftpFileOpenMode.truncate);
          
          // 读取本地文件并上传
          final bytes = await localFile.readAsBytes();
          file.write(Stream.fromIterable([bytes]));
          await file.close();
          client.close();

          service.invoke('uploadComplete', {
            'success': true,
            'path': remotePath,
          });
        } catch (e) {
          print('后台上传失败: $e');
          service.invoke('uploadComplete', {
            'success': false,
            'error': e.toString(),
          });
        }
      }
    });
  }
} 