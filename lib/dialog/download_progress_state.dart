/// 下载进度状态
class DownloadProgressState {
  final double progress;
  final String? status;
  final String url;
  final String path;

  const DownloadProgressState({
    required this.progress,
    this.status,
    required this.url,
    required this.path,
  });

  DownloadProgressState copyWith({
    double? progress,
    String? status,
    String? url,
    String? path,
  }) {
    return DownloadProgressState(
      progress: progress ?? this.progress,
      status: status ?? this.status,
      url: url ?? this.url,
      path: path ?? this.path,
    );
  }
}