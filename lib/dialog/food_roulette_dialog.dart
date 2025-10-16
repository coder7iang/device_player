import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_player/dialog/food_roulette_provider.dart';
import 'package:device_player/dialog/food_roulette_state.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class FoodRouletteDialog extends ConsumerStatefulWidget {
  const FoodRouletteDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<FoodRouletteDialog> createState() => _FoodRouletteDialogState();
}

class _FoodRouletteDialogState extends ConsumerState<FoodRouletteDialog>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodRouletteProvider);
    final notifier = ref.read(foodRouletteProvider.notifier);

    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 标题
            const Text(
              '🍽️ 今天吃什么？',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // 轮盘区域
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 轮盘
                  AnimatedBuilder(
                    animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 2 * pi,
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFF6B6B),
                                  Color(0xFF4ECDC4),
                                  Color(0xFF45B7D1),
                                  Color(0xFF96CEB4),
                                  Color(0xFFFECA57),
                                  Color(0xFFFF9FF3),
                                  Color(0xFF54A0FF),
                                  Color(0xFF5F27CD),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: RoulettePainter(
                                foods: state.foods,
                                selectedIndex: state.selectedIndex,
                                isSpinning: state.isSpinning,
                              ),
                              size: const Size(300, 300),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // 选中的食物显示 - 覆盖在轮盘上方
                  if (state.selectedFood != null) ...[
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: state.isSpinning ? null : () {
                    notifier.startSpin();
                    _startRotation();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: !state.isSpinning ? null : () {
                    notifier.stopSpin();
                    _stopRotation();
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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

  void _startRotation() {
    _rotationController.repeat();
    _scaleController.forward();
  }

  void _stopRotation() {
    _rotationController.stop();
    _scaleController.reverse();
  }
}

class RoulettePainter extends CustomPainter {
  final List<FoodItem> foods;
  final int selectedIndex;
  final bool isSpinning;

  RoulettePainter({
    required this.foods,
    required this.selectedIndex,
    required this.isSpinning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    if (foods.isEmpty) return;

    final double anglePerItem = 2 * pi / foods.length;

    // 绘制扇形
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

      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(path, borderPaint);

      // 绘制文字
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
              Shadow(
                color: Colors.black,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
