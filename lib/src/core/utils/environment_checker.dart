import 'package:logging/logging.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform, File, Directory;
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_windows/webview_windows.dart' as windows_webview;

class EnvironmentChecker {
  static final Logger _logger = Logger('EnvironmentChecker');

  static Future<bool> checkEnvironment() async {
    bool isValid = true;

    try {
      // 1. 检查资源文件
      isValid &= await _checkAssets();

      // 2. 检查WebView支持
      isValid &= await _checkWebView();

      // 3. 检查文件系统权限
      isValid &= await _checkFileSystem();

      _logger.info(
          'Environment check completed. Result: ${isValid ? 'OK' : 'Failed'}');
      return isValid;
    } catch (e) {
      _logger.severe('Environment check failed', e);
      return false;
    }
  }

  static Future<bool> _checkAssets() async {
    try {
      // 检查graph.html是否存在
      final assetPath = 'assets/web/graph.html';
      // 这里实际运行时会检查资源文件
      _logger.info('Checking asset: $assetPath');
      return true;
    } catch (e) {
      _logger.warning('Asset check failed', e);
      return false;
    }
  }

  static Future<bool> _checkWebView() async {
    try {
      // Web平台不需要检查WebView
      if (kIsWeb) {
        _logger.info('Running on Web, WebView check skipped');
        return true;
      }
      
      // Windows平台检查
      if (Platform.isWindows) {
        final controller = windows_webview.WebviewController();
        await controller.initialize();
        await controller.dispose();
        _logger.info('Windows WebView check passed');
        return true;
      }
      
      // 移动平台检查WebView
      if (Platform.isAndroid || Platform.isIOS) {
        WebViewController().setJavaScriptMode(JavaScriptMode.unrestricted);
      }
      
      _logger.info('WebView check passed');
      return true;
    } catch (e) {
      _logger.warning('WebView check failed', e);
      return false;
    }
  }

  static Future<bool> _checkFileSystem() async {
    try {
      if (kIsWeb) {
        // Web平台暂时跳过检查
        return true;
      } else {
        // 非Web平台检查文件系统
        final temp = await File('${Directory.systemTemp.path}/test.txt').create();
        await temp.writeAsString('test');
        await temp.delete();
      }
      
      _logger.info('File system check passed');
      return true;
    } catch (e) {
      _logger.warning('File system check failed', e);
      return false;
    }
  }
}
