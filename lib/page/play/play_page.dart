import 'package:device_player/dialog/music_player_dialog.dart';
import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({Key? key}) : super(key: key);

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  bool _showLaborLawPdf = false;
  PdfControllerPinch? _pdfController;

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _showLaborLawPdf ? _buildLaborLawPdfView() : _buildPlayCards(),
      ),
    );
  }

  /// 默认展示的三个趣味功能卡片
  Widget _buildPlayCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 吃什么转盘
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    SmartDialogUtils.showFoodRoulette();
                  },
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '🍽️ 吃什么',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 劳动法入口（点击后在当前区域展示网页）
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C6FFF), Color(0xFF82B1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openLaborLawPdf,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gavel,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '📖 劳动法',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 音乐播放入口
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 10),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E44AD), Color(0xFFE056FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openMusicPlayer,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '🎵 音乐播放',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openMusicPlayer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MusicPlayerDialog(),
    );
  }

  Future<void> _openLaborLawPdf() async {
    try {
      _pdfController?.dispose();
      final byteData = await rootBundle.load('assets/file/劳动法学习.pdf');
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openData(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        ),
      );
      setState(() {
        _showLaborLawPdf = true;
      });
    } catch (e) {
      SmartDialogUtils.showError('打开劳动法文档失败: $e');
    }
  }

  Widget _buildLaborLawPdfView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _showLaborLawPdf = false;
                });
                _pdfController?.dispose();
                _pdfController = null;
              },
            ),
            const SizedBox(width: 8),
            const Text(
              '劳动法',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _pdfController == null
              ? const SizedBox.shrink()
              : PdfViewPinch(
                  controller: _pdfController!,
                  backgroundDecoration: const BoxDecoration(
                    color: Color.fromARGB(255, 250, 250, 250),
                  ),
                ),
        ),
      ],
    );
  }
}
