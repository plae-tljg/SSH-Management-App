import 'package:flutter/material.dart';
import '../../../connection/domain/entities/connection_config.dart';
import '../controllers/terminal_controller.dart';
import '../widgets/terminal_view.dart';
import '../../data/repositories/terminal_repository_impl.dart';

class TerminalPage extends StatefulWidget {
  final ConnectionConfig connection;

  const TerminalPage({
    Key? key,
    required this.connection,
  }) : super(key: key);

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late final TerminalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TerminalController(TerminalRepositoryImpl());
    _connect();
  }

  Future<void> _connect() async {
    await _controller.connect(widget.connection);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('终端 - ${widget.connection.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _connect,
          ),
        ],
      ),
      body: TerminalView(controller: _controller),
    );
  }
} 