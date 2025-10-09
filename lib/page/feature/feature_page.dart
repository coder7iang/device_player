import 'package:device_player/page/feature/feature_provider.dart';
import 'package:device_player/page/feature/feature_state.dart';
import 'package:device_player/page/feature/feature_data.dart';
import 'package:device_player/page/feature/feature_constants.dart';
import 'package:device_player/page/feature/feature_background.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeaturePage extends ConsumerStatefulWidget {
  final String deviceId;

  const FeaturePage({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  ConsumerState<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends ConsumerState<FeaturePage> {
  // 折叠状态管理 - 每个分类的展开/折叠状态
  late Map<String, bool> _collapseStates;
  
  @override
  void initState() {
    super.initState();
    // 初始化所有分类为展开状态
    _collapseStates = {
      'common': true,    // 常用功能
      'app': true,       // 应用相关
      'system': true,    // 系统相关
      'key': true,       // 按键相关
      'screen': true,    // 屏幕输入
    };
  }
  
  // 切换折叠状态
  void _toggleCollapse(String category) {
    setState(() {
      _collapseStates[category] = !(_collapseStates[category] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final featureState = ref.watch(featureProvider(widget.deviceId));
    final featureNotifier = ref.read(featureProvider(widget.deviceId).notifier);
    
    // 添加调试信息
    print('FeaturePage build - deviceId: ${widget.deviceId}');
    print('FeaturePage build - featureState: $featureState');
    
    
    return Stack(
      children: [
        const Positioned(
          right: 0,
          bottom: 0,
          child: FeatureBackground(
            width: 300,
            height: 300,
          ),
        ),
        DropTarget(
          onDragDone: (details) {
            featureNotifier.onDragDone(details);
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // 常用功能
                        _buildFeatureCardView(
                          category: 'common',
                          title: "常用功能",
                          buttons: FeatureData.getCommonFeatures(),
                          featureState: featureState,
                          featureNotifier: featureNotifier,
                        ),
                        // 应用相关
                        _buildFeatureCardView(
                          category: 'app',
                          title: "应用相关",
                          buttons: FeatureData.getAppFeatures(),
                          featureState: featureState,
                          showPackageSelector: true,
                          featureNotifier: featureNotifier,
                        ),
                        // 系统相关
                        _buildFeatureCardView(
                          category: 'system',
                          title: "系统相关",
                          buttons: FeatureData.getSystemFeatures(),
                          featureState: featureState,
                          featureNotifier: featureNotifier,
                        ),
                        // 按键相关
                        _buildFeatureCardView(
                          category: 'key',
                          title: "按键相关",
                          buttons: FeatureData.getKeyFeatures(),
                          featureState: featureState,
                          featureNotifier: featureNotifier,
                        ),
                        // 屏幕输入
                        _buildFeatureCardView(
                          category: 'screen',
                          title: "屏幕输入",
                          buttons: FeatureData.getScreenInputFeatures(),
                          featureState: featureState,
                          featureNotifier: featureNotifier,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
      ],
    );
  }

  Widget titleView(String title, FeatureState featureState) {
    return Row(
      children: [
        Text(title),
      ],
    );
  }

  Widget _packageNameView(FeatureState featureState, FeatureNotifier featureNotifier) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          featureNotifier.packageSelect(context, ref);
        },
        onHover: (value) {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 10),
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(featureProvider(widget.deviceId));
                  return Container(
                    constraints: const BoxConstraints(
                      maxWidth: 150,
                    ),
                    child: Text(
                      state.packageName.isEmpty ? "选择调试应用" : state.packageName,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF666666),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
      ),
    );
  }

  Container _featureCardView({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.6),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }

  /// 构建功能分类卡片
  Widget _buildFeatureCardView({
    required String category,
    required String title,
    required List<FeatureButton> buttons,
    required FeatureState featureState,
    bool showPackageSelector = false,
    FeatureNotifier? featureNotifier,
  }) {
    final isExpanded = _collapseStates[category] ?? true;
    
    return _featureCardView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 可点击的标题行，支持折叠展开
          InkWell(
            onTap: () => _toggleCollapse(category),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // 折叠展开图标
                  AnimatedRotation(
                    turns: isExpanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 标题行，应用相关分类需要显示包名选择器
                  if (showPackageSelector && featureNotifier != null)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(child: titleView(title, featureState)),
                          _packageNameView(featureState, featureNotifier),
                        ],
                      ),
                    )
                  else
                    Expanded(child: titleView(title, featureState)),
                ],
              ),
            ),
          ),
          // 折叠展开的内容
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              heightFactor: isExpanded ? 1.0 : 0.0,
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  // 使用方格布局显示按钮
                  _buildGridLayout(buttons, featureState, featureNotifier!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建方格布局
  Widget _buildGridLayout(List<FeatureButton> buttons, FeatureState featureState, FeatureNotifier featureNotifier) {
    // 每行显示4个按钮
    const int crossAxisCount = 4;
    final int rowCount = (buttons.length / crossAxisCount).ceil();
    
    return Column(
      children: List.generate(rowCount, (rowIndex) {
        final int startIndex = rowIndex * crossAxisCount;
        final int endIndex = (startIndex + crossAxisCount).clamp(0, buttons.length);
        final List<FeatureButton> rowButtons = buttons.sublist(startIndex, endIndex);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 添加按钮
              ...rowButtons.map((button) => _buildButton(button, featureState, featureNotifier)).toList(),
              // 填充空白位置
              ...List.generate(
                crossAxisCount - rowButtons.length,
                (index) => const Expanded(child: SizedBox()),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 构建单个按钮
  Widget _buildButton(FeatureButton button, FeatureState featureState, FeatureNotifier featureNotifier) {
    Color color = featureState.getColor(button.title);
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _handleButtonClick(button, featureNotifier),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                button.title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 处理按钮点击事件，根据operation区分处理
  void _handleButtonClick(FeatureButton button, FeatureNotifier featureNotifier) {
    print('Button clicked - Operation: ${button.operation}, Title: ${button.title}');
    
    // 根据operation进行不同的处理
    switch (button.operation) {
      // 常用功能
      case FeatureConstants.install:
        print('处理安装应用操作');
        featureNotifier.install();
        break;
      case FeatureConstants.screenshot:
        print('处理截图操作');
        featureNotifier.screenshot();
        break;
      case FeatureConstants.recordScreen:
        print('处理录屏操作');
        featureNotifier.recordScreen();
        break;
      case FeatureConstants.getForegroundActivity:
        print('处理查看当前Activity操作');
        featureNotifier.getForegroundActivity();
        break;
      case FeatureConstants.inputText:
        print('处理输入文本操作');
        featureNotifier.inputText(context);
        break;
      case FeatureConstants.screenMirroring:
        print('处理投屏操作');
        featureNotifier.startScreenMirroring();
        break;
      
      // 应用相关
      case FeatureConstants.uninstall:
        print('处理卸载应用操作');
        featureNotifier.uninstallApk();
        break;
      case FeatureConstants.startApp:
        print('处理启动应用操作');
        featureNotifier.startApp();
        break;
      case FeatureConstants.stopApp:
        print('处理停止应用操作');
        featureNotifier.stopApp();
        break;
      case FeatureConstants.restartApp:
        print('处理重启应用操作');
        featureNotifier.restartApp();
        break;
      case FeatureConstants.clearData:
        print('处理清除数据操作');
        featureNotifier.clearAppData();
        break;
      case FeatureConstants.clearDataRestart:
        print('处理清除数据并重启操作');
        _handleClearDataRestart(featureNotifier);
        break;
      case FeatureConstants.resetPermission:
        print('处理重置权限操作');
        featureNotifier.resetAppPermission();
        break;
      case FeatureConstants.resetPermissionRestart:
        print('处理重置权限并重启操作');
        _handleResetPermissionRestart(featureNotifier);
        break;
      case FeatureConstants.grantPermission:
        print('处理授权所有权限操作');
        featureNotifier.grantAppPermission();
        break;
      case FeatureConstants.getInstallPath:
        print('处理查看应用安装路径操作');
        featureNotifier.getAppInstallPath();
        break;
      case FeatureConstants.saveApk:
        print('处理保存应用APK操作');
        featureNotifier.saveAppApk();
        break;
      case FeatureConstants.saveLog:
        print('处理保存日志操作');
        featureNotifier.saveLog();
        break;
      
      // 系统相关
      case FeatureConstants.getAndroidId:
        print('处理查看AndroidId操作');
        featureNotifier.getAndroidId();
        break;
      case FeatureConstants.getDeviceVersion:
        print('处理查看系统版本操作');
        featureNotifier.getDeviceVersion();
        break;
      case FeatureConstants.getDeviceIp:
        print('处理查看IP地址操作');
        featureNotifier.getDeviceIpAddress();
        break;
      case FeatureConstants.getDeviceMac:
        print('处理查看Mac地址操作');
        featureNotifier.getDeviceMac();
        break;
      case FeatureConstants.reboot:
        print('处理重启手机操作');
        featureNotifier.reboot();
        break;
      case FeatureConstants.getSystemProperty:
        print('处理查看系统属性操作');
        featureNotifier.getSystemProperty();
        break;
      
      // 按键相关
      case FeatureConstants.pressHome:
        print('处理HOME键操作');
        featureNotifier.pressHome();
        break;
      case FeatureConstants.pressBack:
        print('处理返回键操作');
        featureNotifier.pressBack();
        break;
      case FeatureConstants.pressMenu:
        print('处理菜单键操作');
        featureNotifier.pressMenu();
        break;
      case FeatureConstants.pressPower:
        print('处理电源键操作');
        featureNotifier.pressPower();
        break;
      case FeatureConstants.pressVolumeUp:
        print('处理增加音量操作');
        featureNotifier.pressVolumeUp();
        break;
      case FeatureConstants.pressVolumeDown:
        print('处理降低音量操作');
        featureNotifier.pressVolumeDown();
        break;
      case FeatureConstants.pressVolumeMute:
        print('处理静音操作');
        featureNotifier.pressVolumeMute();
        break;
      case FeatureConstants.pressSwitchApp:
        print('处理切换应用操作');
        featureNotifier.pressSwitchApp();
        break;
      case FeatureConstants.remoteControl:
        print('处理遥控器操作');
        featureNotifier.showRemoteControlDialog(context);
        break;
      
      // 屏幕输入
      case FeatureConstants.swipeUp:
        print('处理向上滑动操作');
        featureNotifier.pressSwipeUp();
        break;
      case FeatureConstants.swipeDown:
        print('处理向下滑动操作');
        featureNotifier.pressSwipeDown();
        break;
      case FeatureConstants.swipeLeft:
        print('处理向左滑动操作');
        featureNotifier.pressSwipeLeft();
        break;
      case FeatureConstants.swipeRight:
        print('处理向右滑动操作');
        featureNotifier.pressSwipeRight();
        break;
      case FeatureConstants.screenClick:
        print('处理屏幕点击操作');
        featureNotifier.pressScreen();
        break;
      
      default:
        print('未知操作类型: ${button.operation}');
    }
  }

  /// 处理清除数据并重启操作
  Future<void> _handleClearDataRestart(FeatureNotifier featureNotifier) async {
    await featureNotifier.clearAppData();
    await featureNotifier.startApp();
  }

  /// 处理重置权限并重启操作
  Future<void> _handleResetPermissionRestart(FeatureNotifier featureNotifier) async {
    await featureNotifier.stopApp();
    await featureNotifier.resetAppPermission();
    await featureNotifier.startApp();
  }


}
