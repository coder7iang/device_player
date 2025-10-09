import 'package:device_player/page/log/android_log_page.dart';
import 'package:device_player/page/feature/feature_page.dart';
import 'package:device_player/page/flie/file_manager_page.dart';
import 'package:device_player/page/main/main_provider.dart';
import 'package:device_player/page/main/main_state.dart';
import 'package:device_player/page/play/play_page.dart';
import 'package:device_player/page/setting/setting_page.dart';
import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  @override
  void initState() {
    super.initState();
    // 初始化主页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainState = ref.watch(mainProvider);
    final mainNotifier = ref.read(mainProvider.notifier);

    return Container(
      color: Colors.white,
      child: Row(
        children: <Widget>[
          Container(
            color: Colors.blue.withValues(alpha: 0.05),
            width: 200,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset("images/app_icon.png", width: 50, height: 50),
                const SizedBox(height: 4),
                devicesView(mainState, mainNotifier),
                const SizedBox(height: 20),
                _leftItem("images/ic_feature.svg", "快捷功能", 1, mainState,
                    mainNotifier),
                _leftItem("images/ic_folder.svg", "文件管理", 2, mainState, mainNotifier),
                _leftItem("images/ic_log.svg", "日志管理", 3, mainState, mainNotifier),
                _leftItem("images/ic_settings.svg", "设置页面", 4, mainState, mainNotifier),
                const Spacer(), // 让菜单项向上，动画在底部
                MenuAnimationWidget(
                  onTap: () {
                    mainNotifier.selectPage(5);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: buildContent(mainState.selectedIndex,
                      mainState.deviceId, mainState.adbPath),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent(int value, String deviceId, String adbPath) {
    if (value == 1) {
      return FeaturePage(deviceId: deviceId);
    } else if (value == 2) {
      return FileManagerPage(deviceId);
    } else if (value == 3) {
      return AndroidLogPage(deviceId: deviceId);
    } else if (value == 4) {
      return const SettingPage();
    } else if (value == 5) {
      return const PlayPage();
    } else {
      return Container();
    }
  }

  Widget _leftItem(String image, String name, int index, MainState state,
      MainNotifier notifier) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            notifier.selectPage(index);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: index == state.selectedIndex
                  ? Colors.blue.withValues(alpha: 0.32)
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  image,
                  width: 23,
                  height: 23,
                ),
                const SizedBox(width: 10),
                Text(name),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget devicesView(MainState state, MainNotifier notifier) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          notifier.devicesSelect(context);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 10),
            Container(
              constraints: const BoxConstraints(
                maxWidth: 150,
              ),
              child: Text(
                state.selectedDevice != null
                    ? "${state.selectedDevice!.brand} ${state.selectedDevice!.model}"
                    : "未连接设备",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                ),
              ),
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
    );
  }


}

/// 独立的熊动画组件，避免重建时闪烁
class MenuAnimationWidget extends StatefulWidget {
  final VoidCallback? onTap;
  
  const MenuAnimationWidget({Key? key, this.onTap}) : super(key: key);

  @override
  State<MenuAnimationWidget> createState() => _MenuAnimationWidgetState();
}

class _MenuAnimationWidgetState extends State<MenuAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: Container(
        width: 150,
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 25),
        child: Lottie.asset(
          'assets/animations/joystick.json',
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
          frameRate: FrameRate.max,
          controller: _animationController,
          options: LottieOptions(
            enableMergePaths: true,
          ),
          onLoaded: (composition) {
            // 动画加载完成后设置控制器
            _animationController
              ..duration = composition.duration
              ..repeat();
          },
        ),
      ),
    );
  }

}
