/// 功能操作常量类
class FeatureConstants {
  // 私有构造函数，防止实例化
  FeatureConstants._();

  /// 常用功能操作
  static const String install = 'install';
  static const String screenshot = 'screenshot';
  static const String recordScreen = 'record_screen';
  static const String getForegroundActivity = 'get_foreground_activity';
  static const String inputText = 'input_text';
  static const String screenMirroring = 'screen_mirroring';

  /// 应用相关操作
  static const String uninstall = 'uninstall';
  static const String startApp = 'start_app';
  static const String stopApp = 'stop_app';
  static const String restartApp = 'restart_app';
  static const String clearData = 'clear_data';
  static const String clearDataRestart = 'clear_data_restart';
  static const String resetPermission = 'reset_permission';
  static const String resetPermissionRestart = 'reset_permission_restart';
  static const String grantPermission = 'grant_permission';
  static const String getInstallPath = 'get_install_path';
  static const String saveApk = 'save_apk';
  static const String saveLog = 'save_log';

  /// 系统相关操作
  static const String getAndroidId = 'get_android_id';
  static const String getDeviceVersion = 'get_device_version';
  static const String getDeviceIp = 'get_device_ip';
  static const String getDeviceMac = 'get_device_mac';
  static const String reboot = 'reboot';
  static const String getSystemProperty = 'get_system_property';

  /// 按键相关操作
  static const String pressHome = 'press_home';
  static const String pressBack = 'press_back';
  static const String pressMenu = 'press_menu';
  static const String pressPower = 'press_power';
  static const String pressVolumeUp = 'press_volume_up';
  static const String pressVolumeDown = 'press_volume_down';
  static const String pressVolumeMute = 'press_volume_mute';
  static const String pressSwitchApp = 'press_switch_app';
  static const String remoteControl = 'remote_control';

  /// 屏幕输入操作
  static const String swipeUp = 'swipe_up';
  static const String swipeDown = 'swipe_down';
  static const String swipeLeft = 'swipe_left';
  static const String swipeRight = 'swipe_right';
  static const String screenClick = 'screen_click';

}
