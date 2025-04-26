import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/terminal_controller.dart';

class TerminalView extends StatefulWidget {
  final TerminalController controller;

  const TerminalView({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final _outputController = TextEditingController();
  final _commandController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.outputStream.listen((output) {
      setState(() {
        _outputController.text += output;
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _outputController.dispose();
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _executeCommand() {
    if (_commandController.text.isNotEmpty) {
      final command = _commandController.text;
      _outputController.text += command + '\n';
      widget.controller.executeCommand(command);
      _commandController.clear();
      _scrollToBottom();
    }
  }

  Widget _buildTerminalOutput() {
    final text = _outputController.text;
    final lines = text.split('\n');
    final spans = <TextSpan>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // 检查是否是提示符行
      if (line.contains('@') && line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          spans.add(TextSpan(
            text: parts[0] + ':',
            style: const TextStyle(color: Colors.green),
          ));
          spans.add(TextSpan(
            text: parts[1],
            style: const TextStyle(color: Colors.white),
          ));
        } else {
          spans.add(TextSpan(text: line));
        }
      } else {
        spans.add(TextSpan(text: line));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildTerminalOutput(),
            ),
          ),
        ),
        Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: '输入命令...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _executeCommand(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _executeCommand,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 