import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 短视频缓存服务：把网络视频按 URL 落到本地 tmp 目录，
/// 后续命中缓存就直接走本地文件，避免每次重新下载。
class VideoCacheService {
  VideoCacheService._();
  static final VideoCacheService instance = VideoCacheService._();

  final Dio _dio = Dio();

  /// 同 URL 已在下载时复用 Future，避免并发重复下载
  final Map<String, Future<String>> _inflight = {};

  /// 解析 URL 到本地缓存文件路径；命中缓存立即返回，否则下载后返回。
  /// [onProgress]: 0.0~1.0，仅下载阶段回调
  Future<String> resolve(
    String url, {
    void Function(double progress)? onProgress,
  }) {
    final existing = _inflight[url];
    if (existing != null) return existing;
    final future = _resolveInternal(url, onProgress);
    _inflight[url] = future;
    return future.whenComplete(() => _inflight.remove(url));
  }

  /// 仅查缓存是否命中：命中返回本地路径，未命中返回 null（不发起任何网络请求）
  Future<String?> getCachedPath(String url) async {
    try {
      final cacheDir = await _getCacheDir();
      final filename = _filenameForUrl(url);
      final localPath = '${cacheDir.path}${Platform.pathSeparator}$filename';
      final file = File(localPath);
      if (await file.exists() && await file.length() > 0) {
        return localPath;
      }
    } catch (e) {
      debugPrint('查缓存失败: $e');
    }
    return null;
  }

  /// 后台预取（fire-and-forget）：用于"边播边下"，下载失败静默吞掉
  void prefetch(String url) {
    if (_inflight.containsKey(url)) return;
    resolve(url).catchError((e) {
      debugPrint('预取失败: $url, $e');
      return '';
    });
  }

  Future<String> _resolveInternal(
    String url,
    void Function(double progress)? onProgress,
  ) async {
    final cacheDir = await _getCacheDir();
    final filename = _filenameForUrl(url);
    final localPath = '${cacheDir.path}${Platform.pathSeparator}$filename';
    final localFile = File(localPath);

    if (await localFile.exists() && await localFile.length() > 0) {
      return localPath;
    }

    // 下到 .part 临时文件，成功后再 rename，避免半下载文件被当成完整缓存
    final tempPath = '$localPath.part';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }

    try {
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );
      await tempFile.rename(localPath);
      return localPath;
    } catch (e) {
      debugPrint('视频缓存失败: $url, $e');
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Directory> _getCacheDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}${Platform.pathSeparator}short_video_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _filenameForUrl(String url) {
    final uri = Uri.parse(url);
    final last = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final decoded = Uri.decodeComponent(last);
    final safe = decoded.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (safe.isEmpty) {
      return 'video_${url.hashCode.toRadixString(16)}.mp4';
    }
    return safe;
  }

  /// 清空全部缓存（手动清缓存按钮可调用）
  Future<int> clearAll() async {
    try {
      final dir = await _getCacheDir();
      int count = 0;
      await for (final entity in dir.list()) {
        try {
          await entity.delete(recursive: true);
          count++;
        } catch (_) {}
      }
      return count;
    } catch (e) {
      debugPrint('清空视频缓存失败: $e');
      return 0;
    }
  }
}
