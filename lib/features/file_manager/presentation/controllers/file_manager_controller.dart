import 'dart:async';
import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_manager_repository.dart';

class FileManagerController {
  final FileManagerRepository _repository;
  final _currentPathController = StreamController<String>.broadcast();
  final _filesController = StreamController<List<FileItem>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _loadingController = StreamController<bool>.broadcast();

  String _currentPath = '/';
  bool _isRemote = false;
  final String localBasePath;

  FileManagerController(this._repository, {required this.localBasePath});

  Stream<String> get currentPathStream => _currentPathController.stream;
  Stream<List<FileItem>> get filesStream => _filesController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  String get currentPath => _currentPath;
  bool get isRemote => _isRemote;

  Future<void> setRemoteMode(bool isRemote) async {
    _isRemote = isRemote;
    await refreshCurrentDirectory();
  }

  Future<void> navigateToDirectory(String path) async {
    try {
      _loadingController.add(true);
      _currentPath = path;
      _currentPathController.add(path);
      await refreshCurrentDirectory();
    } catch (e) {
      _errorController.add('导航错误: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> refreshCurrentDirectory() async {
    try {
      _loadingController.add(true);
      final files = _isRemote
          ? await _repository.listRemoteFiles(_currentPath)
          : await _repository.listLocalFiles(_currentPath);
      _filesController.add(files);
    } catch (e) {
      _errorController.add('刷新目录错误: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    try {
      _loadingController.add(true);
      await _repository.downloadFile(remotePath, localPath);
      await refreshCurrentDirectory();
    } catch (e) {
      _errorController.add('下载文件错误: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> uploadFile(String localPath, String remotePath) async {
    try {
      _loadingController.add(true);
      await _repository.uploadFile(localPath, remotePath);
      await refreshCurrentDirectory();
    } catch (e) {
      _errorController.add('上传文件错误: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      _loadingController.add(true);
      if (_isRemote) {
        await _repository.deleteRemoteFile(path);
      } else {
        await _repository.deleteLocalFile(path);
      }
      await refreshCurrentDirectory();
    } catch (e) {
      _errorController.add('删除文件错误: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> createDirectory(String path) async {
    try {
      _loadingController.add(true);
      if (_isRemote) {
        await _repository.createRemoteDirectory(path);
      } else {
        await _repository.createLocalDirectory(path);
      }
      await refreshCurrentDirectory();
    } catch (e) {
      _errorController.add('创建目录错误: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> renameFile(String oldPath, String newPath) async {
    try {
      _loadingController.add(true);
      if (_isRemote) {
        await _repository.renameRemoteFile(oldPath, newPath);
      } else {
        await _repository.renameLocalFile(oldPath, newPath);
      }
      await refreshCurrentDirectory();
    } catch (e) {
      _errorController.add('重命名文件错误: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  void dispose() {
    _currentPathController.close();
    _filesController.close();
    _errorController.close();
    _loadingController.close();
  }
} 