import 'package:device_player/common/app.dart';
import 'package:device_player/page/setting/setting_provider.dart';
import 'package:device_player/services/adb_service.dart';
import 'package:device_player/services/scrcpy_service.dart';
import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  late TextEditingController adbController;
  late TextEditingController scrcpyController;
  late TextEditingController saveFileController;
  late TextEditingController appBackgroundController;

  @override
  void initState() {
    super.initState();
    adbController = TextEditingController();
    scrcpyController = TextEditingController();
    saveFileController = TextEditingController();
    appBackgroundController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final adbPath = AdbService.instance.adbPath;
      if (adbPath.isNotEmpty) {
        final adbSettingNotifier = ref.read(settingProvider.notifier);
        adbSettingNotifier.setAdbPath(adbPath);
      }
      final scrcpyPath = ScrcpyService.instance.scrcpyPath;
      if (scrcpyPath.isNotEmpty) {
        final adbSettingNotifier = ref.read(settingProvider.notifier);
        await adbSettingNotifier.setScrcpyPath(scrcpyPath);
      }
      
      // 加载保存的文件路径
      final app = App();
      final saveFilePath = await app.getSaveFilePath();
      if (saveFilePath.isNotEmpty) {
        final settingNotifier = ref.read(settingProvider.notifier);
        settingNotifier.setSaveFilePath(saveFilePath);
      }
      
      // 加载应用背景路径
      final appBackgroundPath = await app.getAppBackgroundPath();
      if (appBackgroundPath.isNotEmpty) {
        final settingNotifier = ref.read(settingProvider.notifier);
        settingNotifier.setAppBackgroundPath(appBackgroundPath);
      }
    });
  }

  @override
  void dispose() {
    adbController.dispose();
    scrcpyController.dispose();
    saveFileController.dispose();
    appBackgroundController.dispose();
    super.dispose();
  }

  /// 创建路径输入组件
  Widget _buildPathInput({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required Function(String) onChanged,
    required Function() onFileSelect,
    required Function() onTest,
    required String testButtonText,
    bool showTestButton = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                const SizedBox(width: 5),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: hintText,
                      border: const OutlineInputBorder(
                          borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: onFileSelect,
                  child: const Icon(
                    Icons.folder_open,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (showTestButton) 
          SizedBox(
            height: 30,
            child: OutlinedButton(
              style: ButtonStyle(
                side: WidgetStateProperty.all(
                    const BorderSide(color: Colors.grey)),
              ),
              onPressed: onTest,
              child: Text(testButtonText, style: const TextStyle(fontSize: 14)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingState = ref.watch(settingProvider);
    adbController.text = settingState.adbPath;
    scrcpyController.text = settingState.scrcpyPath;
    saveFileController.text = settingState.saveFilePath;
    appBackgroundController.text = settingState.appBackgroundPath;
    final settingNotifier = ref.read(settingProvider.notifier);
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            // ADB 路径输入
            _buildPathInput(
              label: "ADB路径：",
              hintText: "请输入或选择ADB路径",
              controller: adbController,
              onChanged: (value) {
                settingNotifier.setAdbPath(value);
              },
              onFileSelect: () async {
                const typeGroup = XTypeGroup(label: 'adb', extensions: []);
                final file = await openFile(acceptedTypeGroups: [typeGroup]);
                if (file?.path != null) {
                  settingNotifier.setAdbPath(file!.path);
                }
              },
              onTest: () {
                settingNotifier.testAdb();
              },
              testButtonText: "测试",
            ),
            // Scrcpy 路径输入
            _buildPathInput(
              label: "Scrcpy路径：",
              hintText: "请输入或选择Scrcpy路径",
              controller: scrcpyController,
              onChanged: (value) async {
                await settingNotifier.setScrcpyPath(value);
              },
              onFileSelect: () async {
                const typeGroup = XTypeGroup(label: 'scrcpy', extensions: []);
                final file = await openFile(acceptedTypeGroups: [typeGroup]);
                if (file?.path != null) {
                  await settingNotifier.setScrcpyPath(file!.path);
                }
              },
              onTest: () {
                if (settingNotifier.hasScrcpy()) {
                  settingNotifier.testScrcpy();
                } else {
                  settingNotifier.checkScrcpy();
                }
              },
              testButtonText: settingNotifier.hasScrcpy() ? "测试" : "配置",
            ),
            // 保存文件路径输入
            _buildPathInput(
              label: "保存文件位置：",
              hintText: "请选择保存文件的目录",
              controller: saveFileController,
              onChanged: (value) {
                settingNotifier.setSaveFilePath(value);
              },
              onFileSelect: () async {
                final directory = await getDirectoryPath();
                if (directory != null) {
                  settingNotifier.setSaveFilePath(directory);
                }
              },
              onTest: () {
                if (settingNotifier.hasSaveFilePath()) {
                  // 清除保存路径
                  settingNotifier.setSaveFilePath("");
                  SmartDialogUtils.showSuccess("已清除保存路径");
                } else {
                  SmartDialogUtils.showError("请先选择保存文件目录");
                }
              },
              testButtonText: "清除",
              showTestButton: settingNotifier.hasSaveFilePath(), // 只有路径不为空时才显示清除按钮
            ),
            // 应用背景路径输入
            _buildPathInput(
              label: "应用背景：",
              hintText: "请选择应用背景图片或视频",
              controller: appBackgroundController,
              onChanged: (value) {
                settingNotifier.setAppBackgroundPath(value);
              },
              onFileSelect: () async {
                const typeGroup = XTypeGroup(
                  label: '图片/视频', 
                  extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'mp4', 'mov', 'avi', 'mkv', 'webm']
                );
                final file = await openFile(acceptedTypeGroups: [typeGroup]);
                if (file?.path != null) {
                  settingNotifier.setAppBackgroundPath(file!.path);
                }
              },
              onTest: () {
                if (settingNotifier.hasAppBackgroundPath()) {
                  // 清除背景路径
                  settingNotifier.setAppBackgroundPath("");
                  SmartDialogUtils.showSuccess("已清除应用背景");
                } else {
                  SmartDialogUtils.showError("请先选择应用背景文件");
                }
              },
              testButtonText: "清除",
              showTestButton: settingNotifier.hasAppBackgroundPath(), // 只有路径不为空时才显示清除按钮
            ),
          ],
        ),
      ),
    );
  }
}
