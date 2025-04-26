import 'package:flutter/material.dart';
import '../../domain/entities/connection_config.dart';
import '../../../terminal/presentation/pages/terminal_page.dart';

class ConnectionList extends StatelessWidget {
  final List<ConnectionConfig> connections;
  final Function(ConnectionConfig) onConnectionSelected;
  final Function(ConnectionConfig) onConnectionDeleted;
  final bool isExpanded;

  const ConnectionList({
    Key? key,
    required this.connections,
    required this.onConnectionSelected,
    required this.onConnectionDeleted,
    this.isExpanded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 300 : 150,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: connections.isEmpty
          ? const Center(
              child: Text('没有保存的连接'),
            )
          : ListView.builder(
              itemCount: connections.length,
              itemBuilder: (context, index) {
                final connection = connections[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Card(
                    child: InkWell(
                      onTap: () => onConnectionSelected(connection),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            if (isExpanded) ...[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    connection.username.isNotEmpty ? connection.username[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    connection.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (isExpanded)
                                    Text(
                                      '${connection.host}:${connection.port}',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                ],
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.terminal),
                                tooltip: '打开终端',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TerminalPage(connection: connection),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: '删除连接',
                                onPressed: () => onConnectionDeleted(connection),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
} 