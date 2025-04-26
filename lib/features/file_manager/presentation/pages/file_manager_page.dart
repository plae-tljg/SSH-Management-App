import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../connection/domain/entities/connection_config.dart';
import '../controllers/file_manager_controller.dart';
import '../widgets/file_list.dart';
import '../../data/repositories/file_manager_repository_impl.dart';
import '../../domain/entities/file_item.dart';
import 'dart:async';
import '../../../../core/ssh/ssh_connection_manager.dart';
import '../../../../core/background/background_task_handler.dart';

class FileManagerPage extends StatefulWidget {
  final ConnectionConfig? connection;
  final String localBasePath;

  const FileManagerPage({
    Key? key,
    this.connection,
    required this.localBasePath,
  }) : super(key: key);

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> with WidgetsBindingObserver {
  FileManagerController? _controller;
  List<FileItem> _files = [];
  bool _isLoading = false;
  String? _error;
  bool _isRemote = false;
  SSHClient? _sshClient;
  bool _isDisposed = false;
  bool _isReconnecting = false;
  bool _isFilePickerOpen = false;
  final _sshManager = SSHConnectionManager();
  final _backgroundHandler = BackgroundTaskHandler();
  StreamSubscription? _uploadSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
    _backgroundHandler.initialize();
    _setupUploadListener();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _uploadSubscription?.cancel();
    if (widget.connection != null) {
      _sshManager.setFilePickerOpen(widget.connection!.id, false);
    }
    super.dispose();
  }

  void _setupUploadListener() {
    final service = FlutterBackgroundService();
    _uploadSubscription = service.on('uploadComplete').listen((event) {
      if (event != null) {
        final success = event['success'] as bool;
        if (success) {
          final path = event['path'] as String;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('文件上传完成: $path'),
              duration: const Duration(seconds: 2),
            ),
          );
          _controller?.refreshCurrentDirectory();
        } else {
          final error = event['error'] as String;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('文件上传失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRemote) {
      _ensureConnection();
    }
  }

  Future<void> _ensureConnection() async {
    if (_isDisposed || !_isRemote || _isReconnecting || _isFilePickerOpen) return;
    
    try {
      _isReconnecting = true;
      if (widget.connection != null) {
        _sshClient = await _sshManager.getClient(widget.connection!);
        final repository = FileManagerRepositoryImpl(
          _sshClient,
          widget.localBasePath,
        );
        _controller = FileManagerController(
          repository,
          localBasePath: widget.localBasePath,
        );
        _setupStreamListeners();
        await _setRemoteMode(true);
      }
    } catch (e) {
      print('重新连接失败: $e');
    } finally {
      _isReconnecting = false;
    }
  }

  Future<void> _initializeController() async {
    if (widget.connection != null) {
      _sshClient = await _sshManager.getClient(widget.connection!);
    }
    
    final repository = FileManagerRepositoryImpl(
      _sshClient,
      widget.localBasePath,
    );
    _controller = FileManagerController(
      repository,
      localBasePath: widget.localBasePath,
    );
    _setupStreamListeners();
    _setRemoteMode(widget.connection != null);
  }

  void _setupStreamListeners() {
    _controller?.filesStream.listen((files) {
      if (!_isDisposed) {
        setState(() => _files = files);
      }
    });

    _controller?.errorStream.listen((error) {
      if (!_isDisposed) {
        setState(() => _error = error);
      }
    });

    _controller?.loadingStream.listen((isLoading) {
      if (!_isDisposed) {
        setState(() => _isLoading = isLoading);
      }
    });
  }

  Future<void> _setRemoteMode(bool isRemote) async {
    if (!_isDisposed) {
      setState(() => _isRemote = isRemote);
      await _controller?.setRemoteMode(isRemote);
    }
  }

  Future<void> _uploadFile(String targetPath) async {
    if (!_isRemote) return;

    try {
      await _ensureConnection();
      if (widget.connection != null) {
        _sshManager.setFilePickerOpen(widget.connection!.id, true);
      }
      _isFilePickerOpen = true;

      final typeGroup = XTypeGroup(
        label: '所有文件',
        extensions: ['*'],
      );

      final file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      _isFilePickerOpen = false;
      if (widget.connection != null) {
        _sshManager.setFilePickerOpen(widget.connection!.id, false);
      }

      if (file != null) {
        final remotePath = targetPath.endsWith('/') 
            ? '$targetPath${file.name}'
            : '$targetPath/${file.name}';
        
        // 使用后台任务处理器上传文件
        await _backgroundHandler.scheduleUploadTask(
          connection: widget.connection!,
          localPath: file.path,
          remotePath: remotePath,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始后台上传: ${file.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _isFilePickerOpen = false;
      if (widget.connection != null) {
        _sshManager.setFilePickerOpen(widget.connection!.id, false);
      }
      print('上传错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('上传失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnect() {
    if (widget.connection != null) {
      _sshManager.closeConnection(widget.connection!.id);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isRemote) {
          _disconnect();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isRemote ? '远程文件管理器' : '本地文件管理器'),
          leading: _isRemote ? null : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_isRemote)
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () async {
                  try {
                    final typeGroup = XTypeGroup(
                      label: '所有文件',
                      extensions: ['*'],
                    );

                    final file = await openFile(
                      acceptedTypeGroups: [typeGroup],
                    );

                    if (file != null) {
                      final currentPath = _controller?.currentPath ?? '/';
                      final remotePath = currentPath.endsWith('/') 
                          ? '$currentPath${file.name}'
                          : '$currentPath/${file.name}';
                      
                      await _controller?.uploadFile(file.path, remotePath);
                      
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
                tooltip: '上传文件',
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.refreshCurrentDirectory(),
              tooltip: '刷新',
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: () => _showCreateDirectoryDialog(),
              tooltip: '创建目录',
            ),
            if (_isRemote)
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: _disconnect,
                tooltip: '断开连接并返回',
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: () {
                      final parentPath = _getParentPath(_controller?.currentPath ?? '');
                      if (parentPath != null) {
                        _controller?.navigateToDirectory(parentPath);
                      }
                    },
                    tooltip: '返回上级目录',
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showPathInputDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _controller?.currentPath ?? '',
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FileList(
                controller: _controller!,
                files: _files,
                isLoading: _isLoading,
                error: _error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getParentPath(String currentPath) {
    final parts = currentPath.split('/');
    if (parts.length <= 1) return null;
    parts.removeLast();
    return parts.join('/');
  }

  void _showCreateDirectoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新目录'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '目录名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final dirName = controller.text;
              if (dirName.isNotEmpty) {
                final newPath = '${_controller?.currentPath}/$dirName';
                _controller?.createDirectory(newPath);
              }
              Navigator.pop(context);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showPathInputDialog(BuildContext context) {
    final controller = TextEditingController(text: _controller?.currentPath);
    final commonPaths = _isRemote ? [
      '/home/${widget.connection?.username}',
      '/home/${widget.connection?.username}/Downloads',
      '/home/${widget.connection?.username}/Documents',
      '/var/www',
      '/etc',
      '/usr/local',
    ] : [
      widget.localBasePath,
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Pictures',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入路径'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '路径',
                hintText: '输入完整路径',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('常用路径：'),
            const SizedBox(height: 8),
            ...commonPaths.map((path) => ListTile(
              title: Text(path),
              onTap: () {
                controller.text = path;
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newPath = controller.text;
              if (newPath.isNotEmpty) {
                _controller?.navigateToDirectory(newPath);
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 