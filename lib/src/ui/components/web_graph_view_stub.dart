import 'package:flutter/material.dart';

/// 这是一个存根实现，用于非 Web 平台
/// 当在非 Web 平台上尝试使用 WebGraphView 时，会显示一个提示信息
class WebGraphView extends StatelessWidget {
  const WebGraphView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Web Graph View is only available in web platform',
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
        ),
      ),
    );
  }
}
