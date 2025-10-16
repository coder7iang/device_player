import 'dart:io';
import 'package:device_player/dialog/download_progress_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';



/// 下载进度状态管理
class DownloadProgressNotifier extends StateNotifier<DownloadProgressState> {
  DownloadProgressNotifier() : super(const DownloadProgressState(
    progress: 0.0,
    url: '',
    path: '',
  ));

  /// 初始化下载信息
  void init(String url, String path) {
    state = state.copyWith(
      progress: 0.0,
      status: "准备下载...",
      url: url,
      path: path,
    );
    downloadFile();
  }

  /// 更新下载进度
  void updateProgress({
    required double progress,
    String? status,
  }) {
    state = state.copyWith(
      progress: progress,
      status: status,
    );
  }

  /// 显示下载进度对话框
  void showProgress() {
    state = state.copyWith(
      progress: 0.0,
      status: "准备下载...",
    );
  }

  /// 使用dio下载文件
  Future<void> downloadFile() async {
    try {
      // 显示下载进度
      showProgress();

      // 创建dio实例
      final dio = Dio();


      // 确保保存目录存在
      final file = File(state.path);
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 开始下载
      final response = await dio.download(
        state.url,
        state.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final receivedMB = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMB = (total / 1024 / 1024).toStringAsFixed(1);
            debugPrint('下载进度: $progress');
            updateProgress(
              progress: progress,
              status: "已下载 $receivedMB MB / $totalMB MB",
            );
          }
        },
      );

      if (response.statusCode == 200) {
        // 下载完成
        updateProgress(
          progress: 1.0,
          status: "下载完成",
        );
        
        // 延迟一下让用户看到完成状态
        await Future.delayed(const Duration(milliseconds: 500));
        
        SmartDialog.dismiss(tag: 'download_progress', result: true);
        
      } else {
        SmartDialog.dismiss(tag: 'download_progress', result: false);
        throw Exception('下载失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('下载文件失败: $e');
      
      // 更新错误状态
      updateProgress(
        progress: state.progress,
        status: "下载失败: $e",
      );
      
      // 延迟一下让用户看到错误状态
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 调用错误回调
      SmartDialog.dismiss(tag: 'download_progress', result: false);
    }
  }

  

}

/// 下载进度 Provider
final downloadProgressProvider = StateNotifierProvider<DownloadProgressNotifier, DownloadProgressState>(
  (ref) => DownloadProgressNotifier(),
);
