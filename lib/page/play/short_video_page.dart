import 'dart:io';

import 'package:device_player/services/video_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 短视频上下滑动播放页（仿抖音）
class ShortVideoPage extends StatefulWidget {
  const ShortVideoPage({Key? key, required this.urls}) : super(key: key);

  final List<String> urls;

  @override
  State<ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<ShortVideoPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 比纯黑稍亮一点，避免和白底反差过强
      color: const Color(0xFF111114),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) => _VideoItem(
              key: ValueKey(widget.urls[i]),
              url: widget.urls[i],
              active: i == _currentPage,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoItem extends StatefulWidget {
  const _VideoItem({Key? key, required this.url, required this.active})
      : super(key: key);

  final String url;
  final bool active;

  @override
  State<_VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<_VideoItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _showOverlay = false;
  double? _dragValue; // 拖动中以本地值显示，避免被播放进度顶回

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 命中缓存就走本地文件秒开；未命中就直接网络流播放，后台并行落盘给下次用
      final cached =
          await VideoCacheService.instance.getCachedPath(widget.url);

      final c = cached != null
          ? VideoPlayerController.file(File(cached))
          : VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = c;
      await c.initialize();
      if (!mounted) return;
      c.setLooping(true);
      if (widget.active) c.play();
      setState(() => _initialized = true);

      if (cached == null) {
        // 后台下载，不阻塞播放；失败静默
        VideoCacheService.instance.prefetch(widget.url);
      }
    } catch (e) {
      debugPrint('视频初始化失败: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(_VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c == null || !_initialized) return;
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        c.play();
      } else {
        c.pause();
        c.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_initialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _showOverlay = true;
      } else {
        c.play();
        _showOverlay = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Text(
          '视频加载失败',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    final c = _controller;
    if (!_initialized || c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: _togglePlay,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          if (_showOverlay && !c.value.isPlaying)
            const Icon(
              Icons.play_arrow,
              color: Colors.white70,
              size: 80,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: c,
              builder: (context, _) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _fmtDuration(c.value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildScrubber(c)),
                      const SizedBox(width: 8),
                      Text(
                        _fmtDuration(c.value.duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrubber(VideoPlayerController c) {
    final totalMs = c.value.duration.inMilliseconds;
    final maxValue = totalMs > 0 ? totalMs.toDouble() : 1.0;
    final posMs =
        c.value.position.inMilliseconds.toDouble().clamp(0.0, maxValue);
    final value = _dragValue ?? posMs;
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        // 鼠标悬停 / 按下时围绕 thumb 出现的圆环 —— "圆圈放大"效果
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        overlayColor: Colors.white.withValues(alpha: 0.25),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        min: 0,
        max: maxValue,
        value: value.clamp(0.0, maxValue),
        onChanged: totalMs <= 0
            ? null
            : (v) {
                setState(() => _dragValue = v);
              },
        onChangeEnd: totalMs <= 0
            ? null
            : (v) async {
                await c.seekTo(Duration(milliseconds: v.toInt()));
                if (!mounted) return;
                setState(() => _dragValue = null);
              },
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
