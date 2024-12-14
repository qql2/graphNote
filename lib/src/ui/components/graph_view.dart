import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:convert';
import 'web_graph_view.dart';

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
      ..loadFlutterAsset('assets/web/graph.html')
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'GraphChannel',
        onMessageReceived: _handleJsMessage,
      );
    await _mobileController!.loadFlutterAsset('assets/web/graph.html');
  }

  Future<void> _initWindowsWebView() async {
    _windowsController = windows_webview.WebviewController();
    try {
      await _windowsController!.initialize();
      await _windowsController!.loadUrl('assets/web/graph.html');

      // 设置Windows WebView的消息处理
      _windowsController!.webMessage.listen((dynamic message) {
        _handleJsMessage(JavaScriptMessage(message: message.toString()));
      });
    } catch (e) {
      print('Windows WebView initialization failed: $e');
    }
  }

  void _handleJsMessage(JavaScriptMessage message) {
    final data = jsonDecode(message.message);
    switch (data['type']) {
      case 'nodeAdded':
        _handleNodeAdded(data['payload']);
        break;
      case 'edgeAdded':
        _handleEdgeAdded(data['payload']);
        break;
      case 'nodeMoved':
        _handleNodeMoved(data['payload']);
        break;
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
      await _windowsController?.executeScript(script);
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

    await _runJavaScript('handleFlutterMessage(\'$message\')');
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

    await _runJavaScript('handleFlutterMessage(\'$message\')');
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebGraphView();
    }
    if (_isWindows) {
      return windows_webview.Webview(_windowsController!);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return _mobileController == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _mobileController!);
    }
    return const Center(child: Text('Current platform is not supported yet'));
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }
}
