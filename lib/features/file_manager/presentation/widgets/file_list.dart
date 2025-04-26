import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import '../../domain/entities/file_item.dart';
import '../controllers/file_manager_controller.dart';

class FileList extends StatelessWidget {
  final FileManagerController controller;
  final List<FileItem> files;
  final bool isLoading;
  final String? error;

  const FileList({
    Key? key,
    required this.controller,
    required this.files,
    this.isLoading = false,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.refreshCurrentDirectory(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (files.isEmpty) {
      return const Center(child: Text('目录为空'));
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          leading: Icon(
            file.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: file.isDirectory ? Colors.blue : Colors.grey,
          ),
          title: Text(file.name),
          subtitle: Text(
            '${file.size} bytes • ${file.lastModified.toString()}',
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, file),
            itemBuilder: (context) => [
              if (!file.isDirectory)
                const PopupMenuItem(
                  value: 'download',
                  child: Text('下载'),
                ),
              const PopupMenuItem(
                value: 'upload',
                child: Text('上传'),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Text('重命名'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除'),
              ),
            ],
          ),
          onTap: () {
            if (file.isDirectory) {
              controller.navigateToDirectory(file.path);
            }
          },
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action, FileItem file) {
    switch (action) {
      case 'download':
        if (!file.isDirectory) {
          _showDownloadDialog(context, file);
        }
        break;
      case 'upload':
        _showUploadDialog(context);
        break;
      case 'rename':
        _showRenameDialog(context, file);
        break;
      case 'delete':
        _showDeleteConfirmation(context, file);
        break;
    }
  }

  void _showDownloadDialog(BuildContext context, FileItem file) {
    final downloadPath = path.join(controller.localBasePath, file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载文件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要下载 ${file.name} 吗？'),
            const SizedBox(height: 8),
            Text('下载位置: $downloadPath', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              controller.downloadFile(file.path, downloadPath);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('开始下载: ${file.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上传文件'),
        content: const Text('选择要上传的文件'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final typeGroup = XTypeGroup(
                  label: '所有文件',
                  extensions: ['*'],
                );

                final file = await openFile(
                  acceptedTypeGroups: [typeGroup],
                );

                if (file != null) {
                  final remotePath = '${controller.currentPath}/${file.name}';
                  await controller.uploadFile(file.path, remotePath);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('开始上传: ${file.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('上传失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, FileItem file) {
    final controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text;
              if (newName.isNotEmpty) {
                final newPath = file.path.replaceAll(file.name, newName);
                this.controller.renameFile(file.path, newPath);
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除 ${file.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteFile(file.path);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 