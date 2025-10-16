import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// 咖啡奖励弹窗
class CoffeeRewardDialog extends StatefulWidget {
  const CoffeeRewardDialog({Key? key}) : super(key: key);

  @override
  State<CoffeeRewardDialog> createState() => _CoffeeRewardDialogState();
}

class _CoffeeRewardDialogState extends State<CoffeeRewardDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // 启动动画
    _scaleController.forward();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  /// 关闭弹窗
  void _closeDialog() {
    _scaleController.reverse().then((_) {
      _rotationController.stop();
      SmartDialog.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleController.value,
              child: Opacity(
                opacity: _scaleController.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景装饰
                    Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.orange.withValues(alpha: 0.1),
                            Colors.brown.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // // 旋转的光环效果
                    // AnimatedBuilder(
                    //   animation: _rotationController,
                    //   builder: (context, child) {
                    //     return Transform.rotate(
                    //       angle: _rotationController.value * 2 * 3.14159,
                    //       child: Container(
                    //         width: 300,
                    //         height: 300,
                    //         decoration: BoxDecoration(
                    //           shape: BoxShape.circle,
                    //           gradient: SweepGradient(
                    //             colors: [
                    //               Colors.orange.withValues(alpha: 0.3),
                    //               Colors.transparent,
                    //               Colors.orange.withValues(alpha: 0.3),
                    //             ],
                    //             stops: const [0.0, 0.5, 1.0],
                    //           ),
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                    // 咖啡动画
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Lottie.asset(
                        'assets/animations/coffee.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                        frameRate: FrameRate.max,
                      ),
                    ),
                    // 奖励文字
                    Positioned(
                      bottom: 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.orange.shade600],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_cafe,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '奖励一杯咖啡',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 关闭按钮
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _closeDialog,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
