import 'package:adb_player/entity/monkey_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// Monkey 测试结束后的结论对话框
class MonkeyResultDialog extends StatelessWidget {
  final MonkeyResult result;
  final VoidCallback onSaveLog;

  const MonkeyResultDialog({
    Key? key,
    required this.result,
    required this.onSaveLog,
  }) : super(key: key);

  String get _statusText {
    switch (result.status) {
      case MonkeyStatus.completed:
        return '测试完成';
      case MonkeyStatus.stopped:
        return '已停止';
      case MonkeyStatus.error:
        return '测试异常';
    }
  }

  Color get _statusColor {
    switch (result.status) {
      case MonkeyStatus.completed:
        return Colors.green;
      case MonkeyStatus.stopped:
        return Colors.orange;
      case MonkeyStatus.error:
        return Colors.red;
    }
  }

  IconData get _statusIcon {
    switch (result.status) {
      case MonkeyStatus.completed:
        return Icons.check_circle;
      case MonkeyStatus.stopped:
        return Icons.stop_circle;
      case MonkeyStatus.error:
        return Icons.error;
    }
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final hasIssues = result.crashCount > 0 || result.anrCount > 0;
    return Dialog(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Monkey 测试结果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => SmartDialog.dismiss(),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _statusText,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _row('包名', result.packageName),
            _row('配置事件数', result.totalEvents.toString()),
            _row('运行时长', _formatElapsed(result.elapsed)),
            _row(
              '崩溃数',
              result.crashCount.toString(),
              valueColor: result.crashCount > 0 ? Colors.red : null,
              bold: result.crashCount > 0,
            ),
            _row(
              'ANR 数',
              result.anrCount.toString(),
              valueColor: result.anrCount > 0 ? Colors.orange : null,
              bold: result.anrCount > 0,
            ),
            const SizedBox(height: 16),
            if (hasIssues)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '检测到崩溃或 ANR，建议保存日志排查。',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onSaveLog,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('保存日志'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => SmartDialog.dismiss(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
