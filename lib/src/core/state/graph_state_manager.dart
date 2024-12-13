import 'package:flutter/foundation.dart';

class GraphStateManager extends ChangeNotifier {
  // 存储节点数据
  final List<Map<String, dynamic>> nodes = [];
  // 存储边数据
  final List<Map<String, dynamic>> edges = [];

  void addNode(Map<String, dynamic> node) {
    nodes.add(node);
    notifyListeners();
  }

  void addEdge(Map<String, dynamic> edge) {
    edges.add(edge);
    notifyListeners();
  }
}
