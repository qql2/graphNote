import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:convert';
import 'web_graph_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show Factory;

// Windows平台支持
import 'package:webview_windows/webview_windows.dart' as windows_webview;

class GraphView extends StatefulWidget {
  const GraphView({Key? key}) : super(key: key);

  @override
  State<GraphView> createState() => GraphViewState();
}

class GraphViewState extends State<GraphView> {
  WebViewController? _mobileController;
  windows_webview.WebviewController? _windowsController;
  bool _isWindows = false;
  bool _graphInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() async {
    if (kIsWeb) {
      print('web');
    } else if (Platform.isWindows) {
      _isWindows = true;
      await _initWindowsWebView();
    } else if (Platform.isAndroid || Platform.isIOS) {
      await _initMobileWebView();
    } else {
      // 其他平台暂不支持
      print('Current platform is not supported yet');
    }
  }

  Future<void> _initMobileWebView() async {
    _mobileController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _mobileController?.runJavaScript('''
              document.body.style.overscrollBehavior = 'none';
              document.documentElement.style.overscrollBehavior = 'none';
            ''');
          },
        ),
      )
      ..addJavaScriptChannel(
        'GraphChannel',
        onMessageReceived: _handleJsMessage,
      );

    // 读取 HTML 和 JS 内容
    final htmlPath = 'assets/web/graph.html';
    final jsPath = 'assets/web/dist/x6_graph.iife.js';
    final htmlContent = await rootBundle.loadString(htmlPath);
    final jsContent = await rootBundle.loadString(jsPath);

    // 先加载HTML
    await _mobileController!.loadHtmlString(htmlContent);

    // 等待DOM加载完成
    await _mobileController!.runJavaScript('''
      new Promise((resolve) => {
        if (document.readyState === 'complete') {
          resolve();
        } else {
          document.addEventListener('DOMContentLoaded', resolve);
        }
      })
    ''');

    // 注入X6代码
    await _mobileController!.runJavaScript(jsContent);

    // 初始化图形
    await _mobileController!.runJavaScript("initGraph('container')");
    await _addTestNodes();
  }

  Future<void> _initWindowsWebView() async {
    _windowsController = windows_webview.WebviewController();
    try {
      print('Initializing Windows WebView...');
      await _windowsController!.initialize();
      print('Windows WebView initialized');

      // 设置Windows WebView的消息处理
      _windowsController!.webMessage.listen((dynamic message) {
        _handleJsMessage(JavaScriptMessage(message: message.toString()));
      });

      // 读取资源
      final htmlPath = 'assets/web/graph.html';
      final jsPath = 'assets/web/dist/x6_graph.iife.js';
      print('Loading resources...');

      // 读取内容
      final htmlContent = await rootBundle.loadString(htmlPath);
      final jsContent = await rootBundle.loadString(jsPath);

      // 先加载HTML
      await _windowsController!.loadStringContent(htmlContent);

      // 等待DOM加载完成
      await _windowsController!.executeScript('''
        new Promise((resolve) => {
          if (document.readyState === 'complete') {
            resolve();
          } else {
            document.addEventListener('DOMContentLoaded', resolve);
          }
        })
      ''');

      // 注入X6代码
      await _windowsController!.executeScript(jsContent);
      print('HTML and JS loaded');

      // 初始化图形
      await _windowsController!.executeScript("initGraph('container')");
      await _addTestNodes();
      setState(() {
        _graphInitialized = true;
      });
    } catch (e, stackTrace) {
      print('Windows WebView error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _addTestNodes() async {
    print('Adding test nodes...');
    await addNode(
      id: 'test-node-1',
      x: 100,
      y: 100,
      label: 'Test Node 1',
    );

    await addNode(
      id: 'test-node-2',
      x: 300,
      y: 100,
      label: 'Test Node 2',
    );

    // 添加测试连线
    await addEdge(
      source: 'test-node-1',
      target: 'test-node-2',
    );
    print('Test nodes and edge added');
  }

  void _handleJsMessage(JavaScriptMessage message) {
    final data = jsonDecode(message.message);
    switch (data['type']) {
      case 'console':
      case 'info':
      case 'error':
        print('WebView: ${data['payload']}');
        break;
      case 'nodeAdded':
        _handleNodeAdded(data['payload']);
        break;
      case 'edgeAdded':
        _handleEdgeAdded(data['payload']);
        break;
      case 'nodeMoved':
        _handleNodeMoved(data['payload']);
        break;
      default:
        print('Unknown event type: ${data['type']}');
    }
  }

  void _handleNodeAdded(Map<String, dynamic> payload) {
    // 处理节点添加事件
    print('Node added: ${payload['id']} at position: ${payload['position']}');
  }

  void _handleEdgeAdded(Map<String, dynamic> payload) {
    // 处理边添加事件
    print('Edge added: from ${payload['source']} to ${payload['target']}');
  }

  void _handleNodeMoved(Map<String, dynamic> payload) {
    // 处理节点移动事件
    print('Node moved: ${payload['id']} to position: ${payload['position']}');
  }

  Future<void> _runJavaScript(String script) async {
    if (_isWindows) {
      print('Running script on Windows: $script');
      await _windowsController?.executeScript('''
        (async () => {
          try {
            await ${script};
            return true;
          } catch (error) {
            console.error('Script execution failed:', error);
            return false;
          }
        })()
      ''');
    } else {
      await _mobileController?.runJavaScript(script);
    }
  }

  // 添加节点的Flutter接口
  Future<void> addNode({
    required String id,
    required double x,
    required double y,
    required String label,
  }) async {
    final message = jsonEncode({
      'type': 'addNode',
      'payload': {
        'id': id,
        'x': x,
        'y': y,
        'label': label,
      },
    });

    await _runJavaScript('handleFlutterMessage(${jsonEncode(message)})');
  }

  // 添加边的Flutter接口
  Future<void> addEdge({
    required String source,
    required String target,
  }) async {
    final message = jsonEncode({
      'type': 'addEdge',
      'payload': {
        'source': source,
        'target': target,
      },
    });

    await _runJavaScript('handleFlutterMessage(${jsonEncode(message)})');
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebGraphView();
    }
    if (_isWindows) {
      return _graphInitialized
          ? windows_webview.Webview(_windowsController!)
          : const Center(child: CircularProgressIndicator());
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return _mobileController == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: WebViewWidget(
                controller: _mobileController!,
                gestureRecognizers: {
                  Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer()),
                  Factory<HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer()),
                  Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer()),
                  Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                },
              ),
            );
    }
    return const Center(child: Text('Current platform is not supported yet'));
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }
}
