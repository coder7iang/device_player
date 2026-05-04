/// Monkey 测试结束后的结论
class MonkeyResult {
  final String packageName;
  final int totalEvents;
  final Duration elapsed;
  final MonkeyStatus status;
  final int crashCount;
  final int anrCount;
  /// monkey stdout 临时日志的本地路径（用于后续保存）
  final String logPath;

  MonkeyResult({
    required this.packageName,
    required this.totalEvents,
    required this.elapsed,
    required this.status,
    this.crashCount = 0,
    this.anrCount = 0,
    this.logPath = '',
  });
}

enum MonkeyStatus {
  completed,
  stopped,
  error,
}
