import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_player/dialog/download_progress_provider.dart';

class DownloadProgressDialog extends ConsumerStatefulWidget {
  final String url;
  final String path;

  const DownloadProgressDialog(
      {Key? key, required this.url, required this.path})
      : super(key: key);

  @override
  ConsumerState<DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState
    extends ConsumerState<DownloadProgressDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final downloadProgressNotifier =
          ref.read(downloadProgressProvider.notifier);
      downloadProgressNotifier.init(widget.url, widget.path);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadProgressProvider);

    return Dialog(
      child: Container(
        width: 300,
        constraints: const BoxConstraints(
          minHeight: 120,
          maxHeight: 300,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // 进度条
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: state.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 进度百分比
            Text(
              '${(state.progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),

            // 状态信息
            if (state.status != null) ...[
              Flexible(
                child: Text(
                  state.status!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
