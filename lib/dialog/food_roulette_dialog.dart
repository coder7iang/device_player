import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adb_player/dialog/food_roulette_provider.dart';
import 'package:adb_player/dialog/food_roulette_state.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class FoodRouletteDialog extends ConsumerStatefulWidget {
  const FoodRouletteDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<FoodRouletteDialog> createState() => _FoodRouletteDialogState();
}

class _FoodRouletteDialogState extends ConsumerState<FoodRouletteDialog>
    with TickerProviderStateMixin {
  static const double _wheelSize = 300;
  static const int _spinExtraTurns = 5;
  static const Duration _spinDuration = Duration(milliseconds: 4000);
  static final Random _random = Random();

  late final AnimationController _wheelController;
  Animation<double>? _wheelAnimation;
  double _baseAngle = 0;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      duration: _spinDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  double get _currentAngle => _wheelAnimation?.value ?? _baseAngle;

  void _start() {
    final state = ref.read(foodRouletteProvider);
    if (state.foods.isEmpty || state.isSpinning) return;
    ref.read(foodRouletteProvider.notifier).startSpinning();

    // 总角度 = 整圈数 + 随机偏移，落点不可预测
    final totalAngle = _spinExtraTurns * 2 * pi + _random.nextDouble() * 2 * pi;
    final endAngle = _baseAngle + totalAngle;

    setState(() {
      _wheelAnimation = Tween<double>(begin: _baseAngle, end: endAngle).animate(
        CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic),
      );
    });
    _wheelController.forward(from: 0).whenComplete(() {
      _baseAngle = endAngle;
      _commitResultFromAngle(endAngle);
    });
  }

  /// 根据最终落点角度反推位于箭头（角度 π）位置的扇形索引。
  /// 扇形 i 中心在旋转 θ 后的角度 = (i + 0.5) * anglePerItem - π/2 + θ
  /// 令其等于 π（mod 2π）⇒ i + 0.5 ≡ (3π/2 - θ) / anglePerItem (mod N)
  void _commitResultFromAngle(double endAngle) {
    final foods = ref.read(foodRouletteProvider).foods;
    if (foods.isEmpty) return;
    final n = foods.length;
    final anglePerItem = 2 * pi / n;
    final theta = endAngle % (2 * pi);
    final raw = (3 * pi / 2 - theta) % (2 * pi);
    int idx = (raw / anglePerItem - 0.5).round() % n;
    if (idx < 0) idx += n;
    ref.read(foodRouletteProvider.notifier).revealSpin(idx);
  }

  Future<void> _openCustomDialog() async {
    final current = ref.read(foodRouletteProvider);
    final titleController = TextEditingController(text: current.title);
    final foodsController = TextEditingController(
      text: current.foods.map((f) => f.name).join('\n'),
    );

    void submit() {
      final lines = foodsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final notifier = ref.read(foodRouletteProvider.notifier);
      notifier.setTitle(titleController.text);
      if (lines.isEmpty) {
        SmartDialog.dismiss();
        return;
      }
      final newFoods = [
        for (var i = 0; i < lines.length; i++)
          FoodItem(
            id: i,
            name: lines[i],
            category: '',
            description: '',
            address: '',
          ),
      ];
      notifier.setCustomFoods(newFoods);
      setState(() => _baseAngle = 0);
      SmartDialog.dismiss();
    }

    await SmartDialog.show(
      builder: (_) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '自定义转盘',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '标题',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: FoodRouletteState.defaultTitle,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '选项（一行一个，留空行将被忽略）',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: foodsController,
                maxLines: 10,
                minLines: 6,
                decoration: const InputDecoration(
                  hintText: '麦当劳\n肯德基\n沙县小吃',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => SmartDialog.dismiss(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: submit,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    titleController.dispose();
    foodsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodRouletteProvider);

    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              state.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // 转盘 + 左侧固定箭头
            Expanded(
              child: Center(
                child: SizedBox(
                  width: _wheelSize,
                  height: _wheelSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _wheelController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _currentAngle,
                            child: Container(
                              width: _wheelSize,
                              height: _wheelSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: RoulettePainter(foods: state.foods),
                                size: const Size(_wheelSize, _wheelSize),
                              ),
                            ),
                          );
                        },
                      ),
                      // 左侧固定箭头（尖端朝右紧贴转盘左缘）
                      const Positioned(
                        left: -28,
                        top: _wheelSize / 2 - 14,
                        child: _ArrowPointer(),
                      ),
                      // 中心装饰
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                      ),
                      // 选中食物气泡（揭晓后展示）
                      if (state.selectedFood != null && !state.isSpinning)
                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.orange, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🎉 选中了',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.selectedFood!.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.selectedFood!.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: state.isSpinning ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: state.isSpinning ? null : _openCustomDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('自定义'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    SmartDialog.dismiss();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('关闭'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPointer extends StatelessWidget {
  const _ArrowPointer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 28),
      painter: _ArrowPainter(),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, size.height / 2)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 4, false);

    final fill = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoulettePainter extends CustomPainter {
  final List<FoodItem> foods;

  RoulettePainter({required this.foods});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    if (foods.isEmpty) return;

    final double anglePerItem = 2 * pi / foods.length;

    for (int i = 0; i < foods.length; i++) {
      final startAngle = i * anglePerItem - pi / 2;
      final endAngle = (i + 1) * anglePerItem - pi / 2;

      final paint = Paint()
        ..color = _getColorForIndex(i)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          endAngle - startAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // 文字
      final textAngle = startAngle + anglePerItem / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + cos(textAngle) * textRadius;
      final textY = center.dy + sin(textAngle) * textRadius;

      final textPainter = TextPainter(
        text: TextSpan(
          text: foods[i].name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textX - textPainter.width / 2,
          textY - textPainter.height / 2,
        ),
      );
    }
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECA57),
      const Color(0xFFFF9FF3),
      const Color(0xFF54A0FF),
      const Color(0xFF5F27CD),
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant RoulettePainter oldDelegate) {
    return oldDelegate.foods != foods;
  }
}
