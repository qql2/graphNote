import 'package:flutter/material.dart';
import '../components/graph_view.dart';
import '../../core/utils/environment_checker.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindMap Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () async {
              final isValid = await EnvironmentChecker.checkEnvironment();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isValid ? '环境检查通过' : '环境检查失败',
                    ),
                    backgroundColor: isValid ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final graphState =
                  context.findAncestorStateOfType<GraphViewState>();
              if (graphState != null) {
                graphState.addNode(
                  id: 'node-${DateTime.now().millisecondsSinceEpoch}',
                  x: 100,
                  y: 100,
                  label: 'New Node',
                );
              }
            },
          ),
        ],
      ),
      body: const GraphView(),
    );
  }
}
