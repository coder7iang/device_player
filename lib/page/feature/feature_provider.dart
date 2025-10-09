import 'package:desktop_drop/desktop_drop.dart';
import 'package:device_player/common/app.dart';
import 'package:device_player/page/feature/feature_state.dart';
import 'package:device_player/services/adb_service.dart';
import 'package:device_player/services/scrcpy_service.dart';
import 'package:device_player/entity/list_filter_item.dart';
import 'package:device_player/dialog/package_list_provider.dart';
import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 功能页面的 Provider
final featureProvider = StateNotifierProvider.family<FeatureNotifier, FeatureState, String>(
  (ref, deviceId) => FeatureNotifier(deviceId),
);

/// 功能页面的状态管理器
class FeatureNotifier extends StateNotifier<FeatureState> {
  FeatureNotifier(String deviceId) 
      : super(FeatureState(deviceId: deviceId));
  

  
  /// 设置包名
  void setPackageName(String packageName) {
    state = state.copyWith(packageName: packageName);
    AdbService.instance.selectedPackage = packageName;
  }
  
  /// 选择调试应用
  Future<void> packageSelect(BuildContext context, WidgetRef ref) async {
    // 先获取已安装应用列表
    List<ListFilterItem> packages = await AdbService.instance.getInstalledApp();
    // 显示应用选择对话框
    ListFilterItem? selectedPackage =
        await SmartDialogUtils.showPackageListDialog(
            packages, ListFilterItem(state.packageName), () async {
      List<ListFilterItem> packages =
          await AdbService.instance.getInstalledApp();
      final packageListNotifier = ref.read(packageListProvider.notifier);
      packageListNotifier.setData(packages);
    });
    
    String itemTitle = selectedPackage?.itemTitle ?? "";
    // 如果选择了应用，更新当前状态
    if (itemTitle.isNotEmpty) {
      setPackageName(itemTitle);
    }
  }

  



  
  
  /// 选择文件安装应用
  Future<void> install() async {
    try {
      const typeGroup = XTypeGroup(label: 'apk', extensions: ['apk']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file?.path != null && file!.path.isNotEmpty) {
        await installApk(file.path);
      }
    } catch (e) {
      SmartDialogUtils.showError("选择文件失败: $e");
    }
  }
  
  /// 安装 APK
  Future<void> installApk(String apkPath) async {
    if (apkPath.isEmpty) return;
    try {
      // 使用 AdbService 安装 APK
      SmartDialogUtils.showLoading("正在安装应用...");
      final success = await AdbService.instance.installApk(apkPath);
      SmartDialogUtils.hideLoading();
      if (success) {
        SmartDialogUtils.showSuccess("安装成功");
      } else {
        SmartDialogUtils.showError("安装失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("安装失败: $e");
    }
  }
  
  /// 卸载应用
  Future<void> uninstallApk() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择要卸载的应用");
      return;
    }
    bool isConfirm = await SmartDialogUtils.showConfirm(
      title: "确认卸载",
      content: "确定要卸载该应用吗？",
    );
    if (!isConfirm) return;
    
    SmartDialogUtils.showLoading("正在卸载应用...");
    try {
      final success = await AdbService.instance.uninstallApp(state.packageName);
      SmartDialogUtils.hideLoading();
      if (success) {
        SmartDialogUtils.showSuccess("卸载成功");
        setPackageName("");
      } else {
        SmartDialogUtils.showError("卸载失败");
      }
    } catch (e) {
      SmartDialogUtils.hideLoading();
      SmartDialogUtils.showError("卸载失败: $e");
    }
  }




  
  /// 输入文本
  Future<void> inputText(BuildContext context) async {
    // 显示文本输入对话框
    String? text = await SmartDialogUtils.showInput(
      title: "输入文本",
      hintText: "请输入要发送的文本",
    );
    if (text == null || text.isEmpty) return;
    
    SmartDialogUtils.showLoading("正在输入文本...");
    try {
      // 执行 ADB 输入文本命令（自动获取当前设备）
      final success = await AdbService.instance.inputText(text);
      if (success) {
        SmartDialogUtils.showSuccess("文本输入成功: $text");
      } else {
        SmartDialogUtils.showError("文本输入失败: $text");
      }
    } catch (e) {
      SmartDialogUtils.showError("文本输入失败: $text");
      debugPrint("文本输入失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }

  /// 开始投屏
  Future<void> startScreenMirroring() async {
    try {
      // 启动scrcpy投屏服务
      final success = await ScrcpyService.instance.startMirroring();
      if (!success) {
        SmartDialogUtils.showError("投屏启动失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("投屏启动失败: $e");
      debugPrint("投屏启动失败: $e");
    }
  }
  
  /// 截图保存到电脑
  Future<void> screenshot() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    
    
    try {
      // 调用 AdbService 截图方法
      SmartDialogUtils.showLoading("正在截图...");
      bool success = await AdbService.instance.screenshot();
      SmartDialogUtils.hideLoading();
      
      if (success) {
        SmartDialogUtils.showSuccess("截图保存成功");
      } else {
        SmartDialogUtils.showError("截图失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("截图失败: $e");
    }
  }
  
  /// 查看当前 Activity
  Future<void> getForegroundActivity() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    
    
    try {
      // 调用 AdbService 获取前台Activity
      SmartDialogUtils.showLoading("正在获取当前Activity...");
      String? activity = await AdbService.instance.getForegroundActivity();
      SmartDialogUtils.hideLoading();
      
      if (activity != null && activity.isNotEmpty) {
        SmartDialogUtils.showConfirm(title: "当前Activity", content: "当前Activity: $activity");
      } else {
        SmartDialogUtils.showWarning("没有前台Activity");
      }
    } catch (e) {
      SmartDialogUtils.showError("获取Activity失败: $e");
    }
  }
  
  /// 开始录屏
  Future<void> startRecordScreen() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    if (state.isRecording) {
      SmartDialogUtils.showWarning("录屏已在进行中");
      return;
    }
    
    try {
      // 调用 AdbService 开始录屏
      bool success = await AdbService.instance.recordScreen();
      if (success) {
        // 显示录屏计时对话框
        state = state.copyWith(isRecording: true);
        SmartDialogUtils.showRecordingDialog(
          onStop: () {
            // 当用户点击停止按钮时，触发停止录屏
            stopRecordScreen();
          },
        );
      } else {
        SmartDialogUtils.showError("开始录屏失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("开始录屏失败: $e");
    }
  }
  
  /// 停止录屏
  Future<void> stopRecordScreen() async {
    if (!state.isRecording) {
      SmartDialogUtils.showWarning("录屏未在进行中");
      return;
    }
    // 先隐藏录屏计时对话框
    SmartDialogUtils.hideRecordingDialog();
    // 重置录屏状态
    state = state.copyWith(isRecording: false);
    try {
      // 调用 AdbService 停止录屏并保存
      SmartDialogUtils.showLoading("正在停止录屏并保存...");
      bool success = await AdbService.instance.stopRecordAndSave();
      SmartDialogUtils.hideLoading();
      if (success) {
        SmartDialogUtils.showSuccess("录屏保存成功");
      } else {
        SmartDialogUtils.showError("录屏保存失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("停止录屏失败: $e");
    }
  }
  
  /// 处理拖拽完成
  void onDragDone(DropDoneDetails details) async {
    for (var file in details.files) {
      if (file.path.endsWith(".apk")) {
        await installApk(file.path);
      }
    }
  }
  
  /// 启动应用
  Future<void> startApp() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择应用");
      return;
    }
    
    SmartDialogUtils.showLoading("正在启动应用...");
    try {
      bool success = await AdbService.instance.startApp();
      if (success) {
        SmartDialogUtils.showSuccess("应用启动成功");
      } else {
        SmartDialogUtils.showError("应用启动失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("应用启动失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 停止应用
  Future<void> stopApp() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择应用");
      return;
    }

    SmartDialogUtils.showLoading("正在停止应用...");
    try {
      // 这里应该调用实际的 ADB 停止命令
      bool success = await AdbService.instance.stopApp();
      if (success) {
        SmartDialogUtils.showSuccess("应用停止成功");
      } else {
        SmartDialogUtils.showError("应用停止失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("应用停止失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 重启应用
  Future<void> restartApp() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择应用");
      return;
    }
    
    await stopApp();
    await startApp();
  }
  
  /// 清除应用数据
  Future<void> clearAppData() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择应用");
      return;
    }
    bool isConfirm = await SmartDialogUtils.showConfirm(
      content: "确定清除App数据?",
    );
    if (!isConfirm) return;
    SmartDialogUtils.showLoading("正在清除应用数据...");
    try {
      bool success = await AdbService.instance.clearAppData();
      if (success) {
        SmartDialogUtils.showSuccess("应用数据清除成功");
      } else {
        SmartDialogUtils.showError("应用数据清除失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("应用数据清除失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 重置应用权限
  Future<void> resetAppPermission() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择应用");
      return;
    }
    bool isConfirm = await SmartDialogUtils.showConfirm(
      content: "确定重置应用权限?",
    );
    if (!isConfirm) return;
    
    SmartDialogUtils.showLoading("正在重置应用权限...");
    
    try {
      // 这里应该调用实际的 ADB 重置权限命令
      await AdbService.instance.resetAppPermission();
      SmartDialogUtils.showSuccess("应用权限重置成功");
    } catch (e) {
      SmartDialogUtils.showError("应用权限重置失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 授权应用权限
  Future<void> grantAppPermission() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择应用");
      return;
    }
    
    SmartDialogUtils.showLoading("正在授权应用权限...");
    
    try {
      await AdbService.instance.grantAppPermission();
      SmartDialogUtils.showSuccess("应用权限授权成功");
    } catch (e) {
      SmartDialogUtils.showError("应用权限授权失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 获取应用安装路径
  Future<void> getAppInstallPath() async {
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showToast("请先选择应用");
      return;
    }
    
    SmartDialogUtils.showLoading("正在获取应用安装路径...");
    
    try {
      // 这里应该调用实际的 ADB 命令获取安装路径
      String? path = await AdbService.instance.getAppInstallPath();
      if (path.isNotEmpty) {
        SmartDialogUtils.showResult(title: "应用安装路径", content: "应用安装路径: $path");
      } else {
        SmartDialogUtils.showError("获取应用安装路径失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("获取应用安装路径失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  

  /// 保存应用APK到电脑
  Future<void> saveAppApk() async {
    var path = await AdbService.instance.getAppInstallPath();
    if (path.isEmpty) {
      SmartDialogUtils.showError("获取应用安装路径失败");
      return;
    }
    SmartDialogUtils.showLoading("正在保存应用APK到电脑...");
    
    // 尝试获取设置的保存路径
    final app = App();
    final setSavePath = await app.getSaveFilePath();
    String? savePath;
    
    if (setSavePath.isNotEmpty) {
      // 使用设置的保存路径
      savePath = setSavePath;
    } else {
      // 如果没有设置保存路径，让用户选择
      var selectedPath = await getSaveLocation(suggestedName: state.packageName + ".apk");
      if (selectedPath == null) {
        SmartDialogUtils.hideLoading();
        return;
      }
      savePath = selectedPath.path;
    }
    
    if (savePath.isEmpty) {
      SmartDialogUtils.hideLoading();
      SmartDialogUtils.showError("无法获取APK保存路径");
      return;
    }
    
    var success = await AdbService.instance.pullFile(path, savePath);
    SmartDialogUtils.hideLoading();
    if (success) {
      SmartDialogUtils.showSuccess("保存成功");
    } else {
      SmartDialogUtils.showError("保存失败");
    }
    
  }

  /// 保存日志到电脑
  Future<void> saveLog() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    if (state.packageName.isEmpty) {
      SmartDialogUtils.showError("请先选择应用");
      return;
    }
    
    SmartDialogUtils.showLoading("正在拉取应用日志目录到电脑...");
    
    // 尝试获取设置的保存路径
    final app = App();
    final setSavePath = await app.getSaveFilePath();
    String? savePath;
    
    if (setSavePath.isNotEmpty) {
      // 使用设置的保存路径，生成日志目录名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dirName = "${state.packageName}_logs_$timestamp";
      savePath = "$setSavePath/$dirName";
    } else {
      // 如果没有设置保存路径，让用户选择目录
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dirName = "${state.packageName}_logs_$timestamp";
      var selectedPath = await getDirectoryPath();
      if (selectedPath == null) {
        SmartDialogUtils.hideLoading();
        return;
      }
      savePath = "$selectedPath/$dirName";
    }
    
    if (savePath.isEmpty) {
      SmartDialogUtils.hideLoading();
      SmartDialogUtils.showError("无法获取日志保存路径");
      return;
    }
    
    // 调用AdbService拉取日志目录
    var success = await AdbService.instance.saveLog(
      savePath, 
      packageName: state.packageName
    );
    
    SmartDialogUtils.hideLoading();
    if (success) {
      SmartDialogUtils.showSuccess("应用日志目录拉取成功，保存到: $savePath");
    } else {
      SmartDialogUtils.showError("应用日志目录拉取失败，请检查应用是否有日志文件");
    }
  }

  
  
  /// 开始录屏
  Future<void> recordScreen() async {
    await startRecordScreen();
  }
  

  
  /// 获取Android ID
  Future<void> getAndroidId() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }

    SmartDialogUtils.showLoading("正在获取Android ID...");
    
    try {
      String? androidId = await AdbService.instance.getAndroidId();
      if (androidId.isNotEmpty) {
        SmartDialogUtils.showResult(title: "Android ID", content: "Android ID: $androidId");
      } else {
        SmartDialogUtils.showError("获取Android ID失败");
      }
    } catch (e) {
      
      SmartDialogUtils.showError("获取Android ID失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 获取设备版本
  Future<void> getDeviceVersion() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }

    SmartDialogUtils.showLoading("正在获取设备版本...");

    try {
      String version = await AdbService.instance.getDeviceVersion();
      
      if (version.isNotEmpty) {
        SmartDialogUtils.showResult(title: "设备版本", content: "设备版本: $version");
      } else {
        SmartDialogUtils.showError("获取设备版本失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("获取设备版本失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 获取设备IP地址
  Future<void> getDeviceIpAddress() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    SmartDialogUtils.showLoading("正在获取设备IP地址...");
    
    try {
      // 这里应该调用实际的 ADB 命令获取IP地址
      String ipAddress = await AdbService.instance.getDeviceIpAddress();
      
      if (ipAddress.isNotEmpty) {
        SmartDialogUtils.showResult(title: "设备IP地址", content: "设备IP地址: $ipAddress");
      } else {
        SmartDialogUtils.showError("获取设备IP地址失败");
      }
      
      
    } catch (e) {

      SmartDialogUtils.showError("获取设备IP地址失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 获取设备MAC地址
  Future<void> getDeviceMac() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }

    SmartDialogUtils.showLoading("正在获取设备MAC地址...");

    try {
      String macAddress = await AdbService.instance.getDeviceMac();
      if (macAddress.isNotEmpty) {
        SmartDialogUtils.showResult(
            title: "设备MAC地址", content: "设备MAC地址: $macAddress");
      } else {
        SmartDialogUtils.showError("获取设备MAC地址失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("获取设备MAC地址失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 重启设备
  Future<void> reboot() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    SmartDialogUtils.showLoading("正在重启设备...");
    try {
      bool success = await AdbService.instance.reboot();
      if (success) {
        SmartDialogUtils.showSuccess("设备重启成功");
      } else {
        SmartDialogUtils.showError("设备重启失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("重启设备失败: $e");
    }
    SmartDialogUtils.hideLoading();
  }
  
  /// 获取系统属性
  Future<void> getSystemProperty() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    try {
      List<String> list = await AdbService.instance.getSystemProperty();
      if (list.isNotEmpty) {
        var value = await SmartDialogUtils.showPropertyListDialog(
            list.map((e) => ListFilterItem(e)).toList());
        if (value != null) {
          Clipboard.setData(ClipboardData(text: value.itemTitle));
          SmartDialogUtils.showSuccess("已复制到剪切板");
        }
      } else {
        SmartDialogUtils.showError("获取系统属性失败");
      }
    } catch (e) {
      SmartDialogUtils.showError("获取系统属性失败: $e");
    }
    
  }
  
  /// 按下HOME键
  Future<void> pressHome() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    AdbService.instance.pressHome();
  }
  
  /// 按下返回键
  Future<void> pressBack() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    AdbService.instance.pressBack();
  }
  
  /// 按下菜单键
  Future<void> pressMenu() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    AdbService.instance.pressMenu();
  }
  
  /// 按下电源键
  Future<void> pressPower() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressPower();
  }
  
  /// 增加音量
  Future<void> pressVolumeUp() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressVolumeUp();
  }
  
  /// 降低音量
  Future<void> pressVolumeDown() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressVolumeDown();
  }
  
  /// 静音
  Future<void> pressVolumeMute() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressVolumeMute();
  }
  
  /// 切换应用
  Future<void> pressSwitchApp() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressSwitchApp();
  }
  
  /// 显示遥控器对话框
  Future<void> showRemoteControlDialog(BuildContext context) async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    SmartDialogUtils.showRemoteControlDialog();
  }
  
  /// 向上滑动
  Future<void> pressSwipeUp() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressSwipeUp();
  }
  
  /// 向下滑动
  Future<void> pressSwipeDown() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressSwipeDown();
  }
  
  /// 向左滑动
  Future<void> pressSwipeLeft() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressSwipeLeft();
  }
  
  /// 向右滑动
  Future<void> pressSwipeRight() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }
    
    AdbService.instance.pressSwipeRight();
  }
  
  /// 屏幕点击
  Future<void> pressScreen() async {
    if (state.deviceId.isEmpty) {
      SmartDialogUtils.showError("设备未连接");
      return;
    }

    String? text = await SmartDialogUtils.showInputDialog(
      title: "请输入坐标", hintText: "x,y"
    );
    if (text == null || text.isEmpty) return;
    AdbService.instance.pressScreen(text);
  }

  

}
