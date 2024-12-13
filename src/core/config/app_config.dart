class AppConfig {
  // 数据库配置
  static const String dbPath = 'graph.db';
  static const int dbPort = 7687;
  
  // 同步配置
  static const int syncInterval = 300; // 5分钟
  static const int maxRetries = 3;
  
  // UI配置
  static const double defaultNodeWidth = 200.0;
  static const double defaultNodeHeight = 100.0;
} 