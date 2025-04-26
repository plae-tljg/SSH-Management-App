class ConnectionConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKeyPath;
  final String? passphrase;

  ConnectionConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.password,
    this.privateKeyPath,
    this.passphrase,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'privateKeyPath': privateKeyPath,
      'passphrase': passphrase,
    };
  }

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      port: json['port'],
      username: json['username'],
      password: json['password'],
      privateKeyPath: json['privateKeyPath'],
      passphrase: json['passphrase'],
    );
  }
} 