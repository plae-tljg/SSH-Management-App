import 'package:flutter/material.dart';
import '../../domain/entities/connection_config.dart';
import '../../domain/repositories/connection_repository.dart';
import '../widgets/connection_form.dart';
import '../widgets/connection_list.dart';
import '../../../file_manager/presentation/pages/file_manager_page.dart';

class ConnectionPage extends StatefulWidget {
  final ConnectionRepository repository;

  const ConnectionPage({
    Key? key,
    required this.repository,
  }) : super(key: key);

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  List<ConnectionConfig> _connections = [];
  bool _isLoading = true;
  ConnectionConfig? _selectedConnection;
  bool _isSidebarExpanded = false;
  bool _showRightPanel = false;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);
    try {
      final connections = await widget.repository.getAllConnections();
      setState(() {
        _connections = connections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('加载连接失败: $e');
    }
  }

  Future<void> _saveConnection(ConnectionConfig connection) async {
    try {
      if (_selectedConnection != null) {
        await widget.repository.updateConnection(connection);
      } else {
        await widget.repository.saveConnection(connection);
      }
      await _loadConnections();
      setState(() => _selectedConnection = null);
    } catch (e) {
      _showError('保存连接失败: $e');
    }
  }

  Future<void> _deleteConnection(ConnectionConfig connection) async {
    try {
      await widget.repository.deleteConnection(connection.id);
      await _loadConnections();
    } catch (e) {
      _showError('删除连接失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openFileManager(ConnectionConfig connection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileManagerPage(
          connection: connection,
          localBasePath: '/storage/emulated/0/Download', // 默认下载目录
        ),
      ),
    );
  }

  void _handleConnectionSelected(ConnectionConfig connection) {
    setState(() {
      if (_selectedConnection?.id == connection.id) {
        _showRightPanel = !_showRightPanel;
      } else {
        _selectedConnection = connection;
        _showRightPanel = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH连接管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _selectedConnection = null;
                _showRightPanel = true;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isSidebarExpanded ? 300 : 150,
                  child: Stack(
                    children: [
                      ConnectionList(
                        connections: _connections,
                        onConnectionSelected: _handleConnectionSelected,
                        onConnectionDeleted: _deleteConnection,
                        isExpanded: _isSidebarExpanded,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSidebarExpanded = !_isSidebarExpanded;
                            });
                          },
                          child: Container(
                            width: 20,
                            color: Colors.transparent,
                            child: Center(
                              child: Icon(
                                _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                if (_showRightPanel)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (_selectedConnection != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ConnectionForm(
                                      initialConfig: _selectedConnection,
                                      onSave: _saveConnection,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _openFileManager(_selectedConnection!),
                                    icon: const Icon(Icons.folder),
                                    label: const Text('打开文件管理器'),
                                  ),
                                ],
                              ),
                            )
                          else
                            ConnectionForm(
                              initialConfig: _selectedConnection,
                              onSave: _saveConnection,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
} 