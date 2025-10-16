import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:device_player/common/app.dart';

/// 应用背景预览组件
class FeatureBackground extends StatefulWidget {
  final double width;
  final double height;

  const FeatureBackground({
    Key? key,
    this.width = 300,
    this.height = 300,
  }) : super(key: key);

  @override
  State<FeatureBackground> createState() => _FeatureBackgroundState();
}

class _FeatureBackgroundState extends State<FeatureBackground> {
  String _backgroundPath = "";
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadBackgroundPath();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  /// 加载背景文件路径
  Future<void> _loadBackgroundPath() async {
    String backgroundPath = await App().getAppBackgroundPath();

    debugPrint('backgroundPath: $backgroundPath');
    if (mounted) {
      setState(() {
        _backgroundPath = backgroundPath;
      });
      
      // 如果是视频文件，初始化视频播放器
      if (backgroundPath.isNotEmpty) {
        final extension = backgroundPath.toLowerCase().split('.').last;
        final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
        
        if (isVideo) {
          await _initializeVideoPlayer(backgroundPath);
        }
      }
    }
  }

  /// 初始化视频播放器
  Future<void> _initializeVideoPlayer(String videoPath) async {
    try {
      // 释放之前的控制器
      await _videoController?.dispose();
      
      // 创建新的视频控制器
      _videoController = VideoPlayerController.file(File(videoPath));
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // 设置循环播放
        _videoController!.setLooping(true);
        // 开始播放
        _videoController!.play();
      }
    } catch (e) {
      debugPrint('视频播放器初始化失败: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_backgroundPath.isEmpty) {
      // 没有设置背景时显示默认渐变
      return _buildDefaultBackground();
    }

    // 检查文件是否存在
    final file = File(_backgroundPath);
    if (!file.existsSync()) {
      // 文件不存在时显示错误状态
      return _buildErrorBackground();
    }

    // 根据文件扩展名判断是图片还是视频
    final extension = _backgroundPath.toLowerCase().split('.').last;
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);

    if (isVideo) {
      // 视频文件 - 显示视频播放器
      return _buildVideoBackground();
    } else if (isImage) {
      // 图片文件 - 显示图片
      return _buildImageBackground(file);
    } else {
      // 不支持的文件类型
      return _buildUnsupportedBackground();
    }
  }

  /// 构建默认背景
  Widget _buildDefaultBackground() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.transparent,
    );
  }

  /// 构建错误背景
  Widget _buildErrorBackground() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.transparent,
    );
  }

  /// 构建视频背景
  Widget _buildVideoBackground() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      
      child: Stack(
        children: [
          // 视频播放器
          if (_isVideoInitialized && _videoController != null)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            // 视频加载中或失败时显示占位符
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.3, -0.3),
                  radius: 1.2,
                  colors: [
                    Colors.purple.withValues(alpha: 0.15),
                    Colors.blue.withValues(alpha: 0.10),
                    Colors.cyan.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
              
            ),
          // 半透明遮罩
          _buildOverlayMask(),
        ],
      ),
    );
  }

  /// 构建图片背景
  Widget _buildImageBackground(File file) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      
      child: Stack(
        children: [
          // 图片
          Image.file(
            file,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
          ),
          // 半透明遮罩
          _buildOverlayMask(),
        ],
      ),
    );
  }

  /// 构建半透明遮罩
  Widget _buildOverlayMask() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }

  /// 构建不支持文件类型背景
  Widget _buildUnsupportedBackground() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.3, -0.3),
          radius: 1.2,
          colors: [
            Colors.grey.withValues(alpha: 0.12),
            Colors.grey.withValues(alpha: 0.08),
            Colors.grey.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.help_outline,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }
}
