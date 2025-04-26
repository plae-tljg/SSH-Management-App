import '../entities/file_item.dart';

abstract class FileManagerRepository {
  // 远程文件操作
  Future<List<FileItem>> listRemoteFiles(String path);
  Future<void> downloadFile(String remotePath, String localPath);
  Future<void> uploadFile(String localPath, String remotePath);
  Future<void> deleteRemoteFile(String path);
  Future<void> createRemoteDirectory(String path);
  Future<void> renameRemoteFile(String oldPath, String newPath);
  
  // 本地文件操作
  Future<List<FileItem>> listLocalFiles(String path);
  Future<void> deleteLocalFile(String path);
  Future<void> createLocalDirectory(String path);
  Future<void> renameLocalFile(String oldPath, String newPath);
  
  // 文件信息
  Future<FileItem> getFileInfo(String path);
  Future<bool> fileExists(String path);
} 