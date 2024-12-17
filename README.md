# MindMap Graph

一个基于 Flutter 和 AntV X6 的跨平台思维导图应用。

## 开发环境要求

- Flutter SDK (>=3.0.0)
- Node.js & npm
- Windows SDK (用于 Windows 平台开发)
- Android SDK (用于 Android 平台开发)
- Xcode (用于 iOS/macOS 平台开发)

## 项目结构
```
mindmap_graph/
├── assets/
│ └── web/ # Web 相关资源
│ ├── dist/ # TypeScript 编译输出
│ ├── graph.html # 图形渲染模板
│ ├── x6_graph.ts # X6 图形逻辑
│ ├── tsconfig.json # TypeScript 配置
│ └── package.json # npm 配置
├── lib/
│ └── src/
│ ├── core/ # 核心逻辑
│ ├── ui/ # 界面组件
│ └── ...
└── ...

```

## 开发环境设置

1. 安装 Flutter 依赖：

```bash
flutter pub get
```

2. 设置 Web 开发环境：

```bash
cd assets/web
npm install
```

## 开发流程

1. 启动 TypeScript 编译监听：
```bash
cd assets/web
npm run watch
```

2. 在新终端中运行 Flutter 应用：
```bash
# 运行 Web 版本
flutter run -d chrome

# 运行 Windows 版本
flutter run -d windows

# 运行 Android 版本
flutter run -d android

# 运行 iOS 版本
flutter run -d ios
```

## 构建发布版本

```bash
# Web 版本
flutter build web

# Windows 版本
flutter build windows

# Android 版本
flutter build apk

# iOS 版本
flutter build ios
```

## 技术栈

- Flutter - UI 框架
- AntV X6 - 图形渲染引擎
- TypeScript - Web 端开发
- Provider - 状态管理
- WebView - 跨平台图形渲染

## 功能特性

- [ ] 基础节点操作
  - [x] 添加节点
  - [x] 移动节点
  - [ ] 删除节点
  - [ ] 编辑节点
- [ ] 连线操作
  - [x] 添加连线
  - [ ] 删除连线
  - [ ] 编辑连线样式
- [ ] 数据持久化
  - [ ] 本地存储
  - [ ] 云同步
- [ ] 导入导出
  - [ ] JSON 格式
  - [ ] 图片导出

## 调试提示

1. 检查环境：
   - 点击应用栏右上角的检查按钮进行环境检查
   - 查看控制台输出了解详细信息

2. Web 开发：
   - 使用浏览器开发者工具查看 WebView 内容
   - 检查 TypeScript 编译输出

3. 常见问题：
   - 如果图形无法显示，检查 X6 脚本是否正确加载
   - 确保 assets/web/dist 目录存在并包含编译后的 JS 文件

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

[MIT License](LICENSE)
