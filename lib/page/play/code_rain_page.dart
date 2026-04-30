import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class CodeRainPage extends StatefulWidget {
  const CodeRainPage({Key? key}) : super(key: key);

  @override
  State<CodeRainPage> createState() => _CodeRainPageState();
}

class _CodeRainPageState extends State<CodeRainPage>
    with SingleTickerProviderStateMixin {
  static const double _cellWidth = 14;
  static const double _cellHeight = 18;
  static const double _fontSize = 16;
  static const int _tierCount = 6;

  static final List<String> _charset = [
    for (int i = 0; i < 10; i++) '$i',
    for (int i = 0; i < 26; i++) String.fromCharCode(0x41 + i),
    for (final c in [
      'ア','イ','ウ','エ','オ','カ','キ','ク','ケ','コ',
      'サ','シ','ス','セ','ソ','ハ','ヒ','フ','ヘ','ホ',
      'マ','ミ','ム','メ','モ','ヤ','ユ','ヨ','ラ','リ',
    ]) c,
    '@','#','\$','%','&','*','+','-','=','<','>','/','{','}',';',':',
  ];

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final Random _rand = Random();

  List<_Drop> _drops = const [];
  int _cols = 0;
  int _rows = 0;

  // 缓存：char + 强度等级 → 已布局好的 TextPainter
  final Map<String, TextPainter> _painterCache = {};

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    for (final d in _drops) {
      d.advance(dt, _rand, _charset, _rows);
    }
    if (mounted) setState(() {});
  }

  void _ensureSize(Size size) {
    final cols = (size.width / _cellWidth).ceil();
    final rows = (size.height / _cellHeight).ceil();
    if (cols == _cols && rows == _rows) return;
    _cols = cols;
    _rows = rows;
    _drops = List.generate(
      cols,
      (_) => _Drop()..reset(_rand, rows, _charset, initial: true),
    );
  }

  TextPainter _painterFor(String char, int tier, {required bool isHead}) {
    final key = '${isHead ? 'H' : 'T'}$tier$char';
    return _painterCache.putIfAbsent(key, () {
      final color = isHead
          ? Colors.white
          : Color.lerp(
              const Color(0xFF00FF88),
              const Color(0xFF003B1F),
              tier / (_tierCount - 1),
            )!;
      final tp = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(
            color: color,
            fontSize: _fontSize,
            fontFamily: 'monospace',
            fontWeight: isHead ? FontWeight.w600 : FontWeight.w400,
            shadows: isHead
                ? const [
                    Shadow(
                      color: Color(0xFF7CFFC4),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          Navigator.of(context).maybePop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (context, constraints) {
              _ensureSize(constraints.biggest);
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RainPainter(
                        drops: _drops,
                        cellWidth: _cellWidth,
                        cellHeight: _cellHeight,
                        tierCount: _tierCount,
                        painterFor: _painterFor,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 16,
                    bottom: 12,
                    child: Text(
                      '按任意键或点击屏幕退出',
                      style: TextStyle(
                        color: Color(0x4400FF88),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Drop {
  double head = 0;
  double speed = 0;
  int length = 0;
  List<String> chars = const [];

  void reset(Random r, int rows, List<String> charset, {bool initial = false}) {
    // 初始化时把头部分散在屏幕内/外，避免开屏所有列同时落
    head = initial
        ? -r.nextInt(rows * 2).toDouble()
        : -r.nextInt(rows ~/ 2 + 1).toDouble();
    speed = 8 + r.nextDouble() * 22; // rows/sec
    length = 8 + r.nextInt(20);
    chars = List.generate(length, (_) => charset[r.nextInt(charset.length)]);
  }

  void advance(double dt, Random r, List<String> charset, int rows) {
    head += speed * dt;
    if (head - length > rows) {
      reset(r, rows, charset);
      return;
    }
    // 偶尔抖动：随机替换一个字符制造闪烁
    if (r.nextDouble() < 0.06) {
      chars[r.nextInt(chars.length)] = charset[r.nextInt(charset.length)];
    }
  }
}

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  final double cellWidth;
  final double cellHeight;
  final int tierCount;
  final TextPainter Function(String char, int tier, {required bool isHead})
      painterFor;

  _RainPainter({
    required this.drops,
    required this.cellWidth,
    required this.cellHeight,
    required this.tierCount,
    required this.painterFor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 半透明黑色覆盖一层，叠加产生轻微拖影
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black,
    );

    for (int col = 0; col < drops.length; col++) {
      final d = drops[col];
      final x = col * cellWidth;
      final headRow = d.head.floor();
      for (int i = 0; i < d.length; i++) {
        final row = headRow - i;
        if (row < 0) continue;
        final y = row * cellHeight;
        if (y > size.height) continue;

        final isHead = i == 0;
        final tier = isHead
            ? 0
            : ((i - 1) * (tierCount - 1) / (d.length - 1)).floor()
                .clamp(0, tierCount - 1);
        final tp = painterFor(d.chars[i], tier, isHead: isHead);
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}
