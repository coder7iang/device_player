import 'dart:io';

import 'package:adb_player/page/about/about_page.dart';
import 'package:adb_player/page/log/android_log_page.dart';
import 'package:adb_player/page/feature/feature_page.dart';
import 'package:adb_player/page/flie/file_manager_page.dart';
import 'package:adb_player/page/main/main_provider.dart';
import 'package:adb_player/page/main/main_state.dart';
import 'package:adb_player/page/play/play_page.dart';
import 'package:adb_player/page/setting/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:window_manager/window_manager.dart';

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
      child: Column(
        children: [
          _buildTitleBar(mainState),
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                  ),
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
                      _leftItem("images/ic_about.svg", "关于页面", 6, mainState, mainNotifier),
                      const Spacer(),
                      _buildJoyEntry(mainNotifier),
                      const SizedBox(height: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(MainState state) {
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    if (!isDesktop) {
      return const SizedBox.shrink();
    }
    return DragToMoveArea(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Spacer(),
            if (!Platform.isMacOS) ..._windowsButtons(),
          ],
        ),
      ),
    );
  }

  List<Widget> _windowsButtons() {
    return [
      _titleBarIconButton(Icons.remove, () => windowManager.minimize()),
      _titleBarIconButton(Icons.crop_square, () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      }),
      _titleBarIconButton(Icons.close, () => windowManager.close()),
    ];
  }

  Widget _titleBarIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 40,
        child: Icon(icon, size: 16, color: const Color(0xFF555555)),
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
    } else if (value == 6) {
      return const AboutPage();
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
  }  Widget _buildJoyEntry(MainNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => notifier.selectPage(5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFBCFE8)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDB2777).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFBCFE8)),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFFDB2777),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '趣味玩一玩',
                        style: TextStyle(
                          color: Color(0xFF9D174D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '摸鱼专属小工具',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFBE185D),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Color(0xFFDB2777),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

