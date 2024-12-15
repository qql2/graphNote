# WebView Windows 组件更新问题

## 问题描述
在 Windows 平台上使用 webview_windows 包时，WebView 内容的更新（如 X6 图形的初始化和节点添加）不会自动触发组件的重新渲染，导致需要手动热重载才能看到更新后的内容。

## 原因分析
1. WebView 的内容加载和 JavaScript 执行是异步的
2. Flutter 组件默认不会感知到 WebView 内部的状态变化
3. WebView 的初始化和内容加载完成没有反映到 Flutter 的状态管理中

## 解决方案
1. 添加状态变量跟踪 WebView 的初始化状态：
```dart
class GraphViewState extends State<GraphView> {
  bool _graphInitialized = false;  // 添加状态标记
  // ...
}
```

2. 在关键操作完成后触发组件更新：
```dart
await _windowsController!.loadStringContent(fullHtmlContent);
await _addTestNodes();
setState(() {
  _graphInitialized = true;  // 标记初始化完成并触发重建
});
```

3. 根据初始化状态条件渲染：
```dart
@override
Widget build(BuildContext context) {
  if (_isWindows) {
    return _graphInitialized
      ? windows_webview.Webview(_windowsController!)
      : const Center(child: CircularProgressIndicator());
  }
  // ...
}
```

## 最佳实践
1. 为异步操作添加状态标记
2. 使用 setState 确保状态更新反映到 UI
3. 提供加载状态的视觉反馈
4. 在组件完全准备好后再显示 WebView

## 相关代码
- `lib/src/ui/components/graph_view.dart`
- `assets/web/x6_graph.ts`

## 参考链接
- [webview_windows package](https://pub.dev/packages/webview_windows)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro) 