import 'package:flutter/material.dart';
import '../../domain/entities/connection_config.dart';

class ConnectionForm extends StatefulWidget {
  final ConnectionConfig? initialConfig;
  final Function(ConnectionConfig) onSave;

  const ConnectionForm({
    Key? key,
    this.initialConfig,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _privateKeyPathController;
  late TextEditingController _passphraseController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialConfig?.name);
    _hostController = TextEditingController(text: widget.initialConfig?.host);
    _portController = TextEditingController(
      text: widget.initialConfig?.port.toString() ?? '22',
    );
    _usernameController = TextEditingController(text: widget.initialConfig?.username);
    _passwordController = TextEditingController(text: widget.initialConfig?.password);
    _privateKeyPathController = TextEditingController(text: widget.initialConfig?.privateKeyPath);
    _passphraseController = TextEditingController(text: widget.initialConfig?.passphrase);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyPathController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '连接名称'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入连接名称';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _hostController,
            decoration: const InputDecoration(labelText: '主机地址'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入主机地址';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _portController,
            decoration: const InputDecoration(labelText: '端口'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入端口号';
              }
              if (int.tryParse(value) == null) {
                return '请输入有效的端口号';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: '用户名'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入用户名';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: '密码'),
            obscureText: true,
          ),
          TextFormField(
            controller: _privateKeyPathController,
            decoration: const InputDecoration(labelText: '私钥路径'),
          ),
          TextFormField(
            controller: _passphraseController,
            decoration: const InputDecoration(labelText: '私钥密码'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveConnection,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _saveConnection() {
    if (_formKey.currentState!.validate()) {
      final connection = ConnectionConfig(
        id: widget.initialConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        privateKeyPath: _privateKeyPathController.text.isEmpty ? null : _privateKeyPathController.text,
        passphrase: _passphraseController.text.isEmpty ? null : _passphraseController.text,
      );
      widget.onSave(connection);
    }
  }
} 