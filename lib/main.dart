import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindmap_graph/src/core/utils/logger.dart';
import 'package:mindmap_graph/src/core/utils/environment_checker.dart';
import 'package:mindmap_graph/src/ui/pages/home_page.dart';
import 'package:mindmap_graph/src/core/state/graph_state_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志
  AppLogger.init();

  // 检查环境
  final environmentValid = await EnvironmentChecker.checkEnvironment();
  if (!environmentValid) {
    AppLogger.error('Environment check failed');
    // 这里可以选择是否继续运行
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GraphStateManager(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindMap Graph',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}
