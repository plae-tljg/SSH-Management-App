import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as path;
import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_manager_repository.dart';
import '../../../connection/domain/entities/connection_config.dart';

class FileManagerRepositoryImpl implements FileManagerRepository {
  final SSHClient? _sshClient;
  final String _localBasePath;

  FileManagerRepositoryImpl(this._sshClient, this._localBasePath);

  @override
  Future<List<FileItem>> listRemoteFiles(String remotePath) async {
    if (_sshClient == null) throw Exception('SSH client not initialized');

    final sftp = await _sshClient!.sftp();
    final entries = await sftp.listdir(remotePath);
    
    final files = entries.map((entry) {
      final attrs = entry.attr;
      return FileItem(
        name: entry.filename,
        path: path.join(remotePath, entry.filename),
        isDirectory: attrs.isDirectory,
        size: attrs.size ?? 0,
        lastModified: DateTime.fromMillisecondsSinceEpoch((attrs.modifyTime ?? 0) * 1000),
        permissions: _formatPermissions(attrs.mode?.value ?? 0),
        owner: attrs.userID?.toString() ?? '0',
        group: attrs.groupID?.toString() ?? '0',
      );
    }).toList();

    return _sortFiles(files);
  }

  @override
  Future<List<FileItem>> listLocalFiles(String localPath) async {
    final directory = Directory(localPath);
    final entities = await directory.list().toList();
    
    final files = entities.map((entity) {
      final stat = entity.statSync();
      return FileItem(
        name: path.basename(entity.path),
        path: entity.path,
        isDirectory: entity is Directory,
        size: stat.size,
        lastModified: stat.modified,
        permissions: _formatLocalPermissions(stat.mode),
        owner: '0',
        group: '0',
      );
    }).toList();

    return _sortFiles(files);
  }

  List<FileItem> _sortFiles(List<FileItem> files) {
    // 首先按类型排序（目录在前）
    files.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      
      // 然后按名称排序（忽略大小写）
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      
      // 处理隐藏文件（以点开头的文件）
      final aIsHidden = aName.startsWith('.');
      final bIsHidden = bName.startsWith('.');
      
      if (aIsHidden && !bIsHidden) return -1;
      if (!aIsHidden && bIsHidden) return 1;
      
      return aName.compareTo(bName);
    });
    
    return files;
  }

  @override
  Future<void> downloadFile(String remotePath, String localPath) async {
    if (_sshClient == null) throw Exception('SSH client not initialized');

    final sftp = await _sshClient!.sftp();
    final file = await sftp.open(remotePath);
    final localFile = File(localPath);
    
    await localFile.create(recursive: true);
    final sink = localFile.openWrite();
    
    try {
      await for (final data in file.read()) {
        sink.add(data);
      }
      await sink.close();
      await file.close();
    } catch (e) {
      await sink.close();
      await file.close();
      rethrow;
    }
  }

  @override
  Future<void> uploadFile(String localPath, String remotePath) async {
    if (_sshClient == null) throw Exception('SSH client not initialized');

    final sftp = await _sshClient!.sftp();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.write | SftpFileOpenMode.create | SftpFileOpenMode.truncate);
    final localFile = File(localPath);
    
    final bytes = await localFile.readAsBytes();
    await file.write(Stream.value(bytes));
    await file.close();
  }

  @override
  Future<void> deleteRemoteFile(String path) async {
    if (_sshClient == null) throw Exception('SSH client not initialized');

    final sftp = await _sshClient!.sftp();
    await sftp.remove(path);
  }

  @override
  Future<void> createRemoteDirectory(String path) async {
    if (_sshClient == null) throw Exception('SSH client not initialized');

    final sftp = await _sshClient!.sftp();
    await sftp.mkdir(path);
  }

  @override
  Future<void> renameRemoteFile(String oldPath, String newPath) async {
    if (_sshClient == null) throw Exception('SSH client not initialized');

    final sftp = await _sshClient!.sftp();
    await sftp.rename(oldPath, newPath);
  }

  @override
  Future<void> deleteLocalFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> createLocalDirectory(String path) async {
    final directory = Directory(path);
    await directory.create(recursive: true);
  }

  @override
  Future<void> renameLocalFile(String oldPath, String newPath) async {
    final file = File(oldPath);
    await file.rename(newPath);
  }

  @override
  Future<FileItem> getFileInfo(String filePath) async {
    if (_sshClient != null) {
      final sftp = await _sshClient!.sftp();
      final stat = await sftp.stat(filePath);
      return FileItem(
        name: path.basename(filePath),
        path: filePath,
        isDirectory: stat.isDirectory,
        size: stat.size ?? 0,
        lastModified: DateTime.fromMillisecondsSinceEpoch((stat.modifyTime ?? 0) * 1000),
        permissions: _formatPermissions(stat.mode?.value ?? 0),
        owner: stat.userID?.toString() ?? '0',
        group: stat.groupID?.toString() ?? '0',
      );
    } else {
      final file = File(filePath);
      final stat = await file.stat();
      return FileItem(
        name: path.basename(file.path),
        path: filePath,
        isDirectory: await file.exists() && stat.type == FileSystemEntityType.directory,
        size: stat.size,
        lastModified: stat.modified,
        permissions: _formatLocalPermissions(stat.mode),
        owner: '0',
        group: '0',
      );
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    if (_sshClient != null) {
      final sftp = await _sshClient!.sftp();
      try {
        await sftp.stat(path);
        return true;
      } catch (e) {
        return false;
      }
    } else {
      final file = File(path);
      return await file.exists();
    }
  }

  String _formatPermissions(int permissions) {
    final perms = permissions & 0xFFF;
    return perms.toRadixString(8).padLeft(3, '0');
  }

  String _formatLocalPermissions(int mode) {
    return (mode & 0xFFF).toRadixString(8).padLeft(3, '0');
  }
} 