import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class WebGraphView extends StatefulWidget {
  const WebGraphView({Key? key}) : super(key: key);

  @override
  State<WebGraphView> createState() => _WebGraphViewState();
}

class _WebGraphViewState extends State<WebGraphView> {
  final String viewId = 'x6-container-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    // 注册视图工厂
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final div = html.DivElement()
        ..id = 'container'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '1px solid #ddd';

      // 注入 AntV X6 脚本
      _injectX6Script(() {
        _initGraph(div.id);
      });

      return div;
    });
  }

  void _injectX6Script(Function callback) {
    final script = html.ScriptElement()
      ..src = 'https://cdn.jsdelivr.net/npm/@antv/x6@2.x/dist/x6.js'
      ..type = 'text/javascript';

    script.onLoad.listen((_) {
      callback();
    });

    html.document.head!.append(script);
  }

  void _initGraph(String containerId) {
    final js = '''
      const graph = new X6.Graph({
        container: document.getElementById('$containerId'),
        grid: true,
        autoResize: true,
        connecting: {
          snap: true,
          allowBlank: false,
          allowLoop: true,
          highlight: true,
        },
      });

      window.graph = graph;  // 使图形实例全局可访问
      
      // 添加消息处理
      window.handleFlutterMessage = function(message) {
        const data = JSON.parse(message);
        switch(data.type) {
          case 'addNode':
            addNode(data.payload);
            break;
          case 'addEdge':
            addEdge(data.payload);
            break;
        }
      };

      function addNode(nodeData) {
        const node = graph.addNode({
          id: nodeData.id,
          x: nodeData.x,
          y: nodeData.y,
          width: nodeData.width || 100,
          height: nodeData.height || 40,
          label: nodeData.label,
          attrs: {
            body: {
              fill: '#fff',
              stroke: '#8f8f8f',
              strokeWidth: 1,
            },
          },
        });
      }

      function addEdge(edgeData) {
        const edge = graph.addEdge({
          source: edgeData.source,
          target: edgeData.target,
          attrs: {
            line: {
              stroke: '#8f8f8f',
              strokeWidth: 1,
            },
          },
        });
      }
    ''';

    html.document.querySelector('body')!.appendHtml('<script>$js</script>');
  }

  void addNode(String id, double x, double y, String label) {
    final js = '''
      handleFlutterMessage(JSON.stringify({
        type: 'addNode',
        payload: {
          id: '$id',
          x: $x,
          y: $y,
          label: '$label'
        }
      }));
    ''';

    html.document.querySelector('body')!.appendHtml('<script>$js</script>');
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: viewId,
    );
  }
}
