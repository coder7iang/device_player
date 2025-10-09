import 'package:device_player/common/icon_font.dart';
import 'package:device_player/page/feature/feature_constants.dart';
import 'package:flutter/material.dart';

/// 功能按钮数据类
class FeatureButton {
  final IconData icon;
  final String title;
  final String operation;

  const FeatureButton({
    required this.icon,
    required this.title,
    required this.operation,
  });
}


/// 功能数据管理类
class FeatureData {
  /// 常用功能
  static List<FeatureButton> getCommonFeatures() {
    return [
      const FeatureButton(
        icon: IconFont.install,
        title: "安装应用",
        operation: FeatureConstants.install,
      ),
      const FeatureButton(
        icon: IconFont.screenshot,
        title: "截图保存到电脑",
        operation: FeatureConstants.screenshot,
      ),
      const FeatureButton(
        icon: IconFont.screenRecording,
        title: "开始录屏",
        operation: FeatureConstants.recordScreen,
      ),
      const FeatureButton(
        icon: IconFont.currentActivity,
        title: "查看当前Activity",
        operation: FeatureConstants.getForegroundActivity,
      ),
      const FeatureButton(
        icon: IconFont.input,
        title: "输入文本",
        operation: FeatureConstants.inputText,
      ),
      const FeatureButton(
        icon: IconFont.remoteControl,
        title: "投屏",
        operation: FeatureConstants.screenMirroring,
      ),
    ];
  }

  /// 应用相关
  static List<FeatureButton> getAppFeatures() {
    return [
      const FeatureButton(
        icon: IconFont.uninstall,
        title: "卸载应用",
        operation: FeatureConstants.uninstall,
      ),
      const FeatureButton(
        icon: IconFont.start,
        title: "启动应用",
        operation: FeatureConstants.startApp,
      ),
      const FeatureButton(
        icon: IconFont.stop,
        title: "停止运行",
        operation: FeatureConstants.stopApp,
      ),
      const FeatureButton(
        icon: IconFont.rerun,
        title: "重启应用",
        operation: FeatureConstants.restartApp,
      ),
      const FeatureButton(
        icon: IconFont.clean,
        title: "清除数据",
        operation: FeatureConstants.clearData,
      ),
      const FeatureButton(
        icon: IconFont.cleanRerun,
        title: "清除数据并重启应用",
        operation: FeatureConstants.clearDataRestart,
      ),
      const FeatureButton(
        icon: IconFont.reset,
        title: "重置权限",
        operation: FeatureConstants.resetPermission,
      ),
      const FeatureButton(
        icon: IconFont.resetRerun,
        title: "重置权限并重启应用",
        operation: FeatureConstants.resetPermissionRestart,
      ),
      const FeatureButton(
        icon: IconFont.authorize,
        title: "授权所有权限",
        operation: FeatureConstants.grantPermission,
      ),
      const FeatureButton(
        icon: IconFont.apkPath,
        title: "查看应用安装路径",
        operation: FeatureConstants.getInstallPath,
      ),
      const FeatureButton(
        icon: IconFont.save,
        title: "保存应用APK到电脑",
        operation: FeatureConstants.saveApk,
      ),
      const FeatureButton(
        icon: IconFont.log,
        title: "保存日志到电脑",
        operation: FeatureConstants.saveLog,
      ),
    ];
  }

  /// 系统相关
  static List<FeatureButton> getSystemFeatures() {
    return [
      const FeatureButton(
        icon: IconFont.android,
        title: "查看AndroidId",
        operation: FeatureConstants.getAndroidId,
      ),
      const FeatureButton(
        icon: IconFont.version,
        title: "查看系统版本",
        operation: FeatureConstants.getDeviceVersion,
      ),
      const FeatureButton(
        icon: IconFont.ip,
        title: "查看IP地址",
        operation: FeatureConstants.getDeviceIp,
      ),
      const FeatureButton(
        icon: IconFont.macAddress,
        title: "查看Mac地址",
        operation: FeatureConstants.getDeviceMac,
      ),
      const FeatureButton(
        icon: IconFont.restart,
        title: "重启手机",
        operation: FeatureConstants.reboot,
      ),
      const FeatureButton(
        icon: IconFont.systemProperty,
        title: "查看系统属性",
        operation: FeatureConstants.getSystemProperty,
      ),
    ];
  }

  /// 按键相关
  static List<FeatureButton> getKeyFeatures() {
    return [
      const FeatureButton(
        icon: IconFont.home,
        title: "HOME键",
        operation: FeatureConstants.pressHome,
      ),
      const FeatureButton(
        icon: IconFont.back,
        title: "返回键",
        operation: FeatureConstants.pressBack,
      ),
      const FeatureButton(
        icon: IconFont.menu,
        title: "菜单键",
        operation: FeatureConstants.pressMenu,
      ),
      const FeatureButton(
        icon: IconFont.power,
        title: "电源键",
        operation: FeatureConstants.pressPower,
      ),
      const FeatureButton(
        icon: IconFont.volumeUp,
        title: "增加音量",
        operation: FeatureConstants.pressVolumeUp,
      ),
      const FeatureButton(
        icon: IconFont.volumeDown,
        title: "降低音量",
        operation: FeatureConstants.pressVolumeDown,
      ),
      const FeatureButton(
        icon: IconFont.mute,
        title: "静音",
        operation: FeatureConstants.pressVolumeMute,
      ),
      const FeatureButton(
        icon: IconFont.switchApp,
        title: "切换应用",
        operation: FeatureConstants.pressSwitchApp,
      ),
      const FeatureButton(
        icon: IconFont.remoteControl,
        title: "遥控器",
        operation: FeatureConstants.remoteControl,
      ),
    ];
  }

  /// 屏幕输入
  static List<FeatureButton> getScreenInputFeatures() {
    return [
      const FeatureButton(
        icon: IconFont.swipeUp,
        title: "向上滑动",
        operation: FeatureConstants.swipeUp,
      ),
      const FeatureButton(
        icon: IconFont.swipeDown,
        title: "向下滑动",
        operation: FeatureConstants.swipeDown,
      ),
      const FeatureButton(
        icon: IconFont.swipeLeft,
        title: "向左滑动",
        operation: FeatureConstants.swipeLeft,
      ),
      const FeatureButton(
        icon: IconFont.swipeRight,
        title: "向右滑动",
        operation: FeatureConstants.swipeRight,
      ),
      const FeatureButton(
        icon: IconFont.click,
        title: "屏幕点击",
        operation: FeatureConstants.screenClick,
      ),
    ];
  }

}
