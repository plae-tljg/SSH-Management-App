class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime lastModified;
  final String permissions;
  final String owner;
  final String group;

  FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
    required this.permissions,
    required this.owner,
    required this.group,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'isDirectory': isDirectory,
      'size': size,
      'lastModified': lastModified.toIso8601String(),
      'permissions': permissions,
      'owner': owner,
      'group': group,
    };
  }

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'],
      path: json['path'],
      isDirectory: json['isDirectory'],
      size: json['size'],
      lastModified: DateTime.parse(json['lastModified']),
      permissions: json['permissions'],
      owner: json['owner'],
      group: json['group'],
    );
  }
} 