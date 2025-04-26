import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/ssh/ssh_connection_manager.dart';
import 'features/connection/data/repositories/connection_repository_impl.dart';
import 'features/connection/presentation/pages/connection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置生命周期监听
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.paused.toString()) {
      // 应用进入后台
      print('应用进入后台，保持SSH连接');
    } else if (msg == AppLifecycleState.resumed.toString()) {
      // 应用回到前台
      print('应用回到前台，检查SSH连接');
    }
    return null;
  });

  // 初始化应用
  final prefs = await SharedPreferences.getInstance();
  final repository = ConnectionRepositoryImpl(prefs);
  
  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ConnectionRepositoryImpl repository;

  const MyApp({
    Key? key,
    required this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSH Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ConnectionPage(repository: repository),
    );
  }
}
