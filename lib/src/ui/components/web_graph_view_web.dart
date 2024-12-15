import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:js' as js;
import 'dart:async';

class WebGraphView extends StatefulWidget {
  const WebGraphView({Key? key}) : super(key: key);

  @override
  State<WebGraphView> createState() => _WebGraphViewState();
}

class _WebGraphViewState extends State<WebGraphView> {
  late final String containerId;

  @override
  void initState() {
    super.initState();
    containerId = 'x6-container-${DateTime.now().millisecondsSinceEpoch}';
    print('initState: containerId = $containerId');

    // 清理可能存在的旧元素
    final oldElement = html.document.getElementById(containerId);
    oldElement?.remove();

    // 先注册视图工厂
    ui.platformViewRegistry.registerViewFactory(containerId, (int registryId) {
      print('registerViewFactory: containerId = $containerId');
      final div = html.DivElement()
        ..id = containerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '1px solid #ddd';

      // 先加载 X6
      print('Loading X6...');
      // _loadScript('https://unpkg.com/@antv/x6@1.1.1/dist/x6.js').then((_) {
      //   print('X6 loaded, loading graph logic...');
      //   // X6 加载完成后再加载我们的图形逻辑
      // });
      html.HttpRequest.getString('assets/web/dist/x6_graph.iife.js')
          .then((String jsContent) {
        print('Graph logic loaded, length: ${jsContent.length}');
        _injectScript(jsContent);
        _setupGraph(containerId);
      });

      return div;
    });

    // 等待 DOM 更新后初始化图形
    html.window.onLoad.listen((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (html.document.getElementById(containerId) != null) {
          print('Container found, setting up graph...');
          _setupGraph(containerId);
        } else {
          print('Container not found: $containerId');
        }
      });
    });
  }

  Future<void> _loadScript(String src) {
    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src = src
      ..type = 'text/javascript';
    script.onLoad.listen((_) => completer.complete());
    html.document.head!.append(script);
    return completer.future;
  }

  void _injectScript(String content) {
    final script = html.ScriptElement()
      ..type = 'text/javascript'
      ..text = content;
    html.document.head!.append(script);
  }

  void _setupGraph(String containerId) {
    print('Setting up graph...');
    js.context['onNodeMoved'] = (dynamic data) {
      if (data is js.JsObject) {
        final id = data['id'];
        final position = data['position'];
        print('Node moved: $id to position: $position');
      } else {
        print('Unexpected data type: ${data.runtimeType}');
      }
    };

    // 初始化图形
    print('Initializing graph with containerId: $containerId');
    js.context.callMethod('initGraph', [containerId]);

    // 添加测试节点
    print('Adding test nodes...');
    addNode(
      id: 'test-node-1',
      x: 100,
      y: 100,
      label: 'Test Node 1',
    );

    addNode(
      id: 'test-node-2',
      x: 300,
      y: 100,
      label: 'Test Node 2',
    );

    // 添加测试连线
    addEdge(
      source: 'test-node-1',
      target: 'test-node-2',
    );
  }

  // 添加节点
  void addNode({
    required String id,
    required double x,
    required double y,
    required String label,
  }) {
    js.context.callMethod('addNode', [
      js.JsObject.jsify({
        'id': id,
        'x': x,
        'y': y,
        'label': label,
      })
    ]);
  }

  // 添加边
  void addEdge({
    required String source,
    required String target,
  }) {
    js.context.callMethod('addEdge', [
      js.JsObject.jsify({
        'source': source,
        'target': target,
      })
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: containerId,
    );
  }

  @override
  void dispose() {
    // 清理 DOM 元素
    final element = html.document.getElementById(containerId);
    element?.remove();
    super.dispose();
  }
}
