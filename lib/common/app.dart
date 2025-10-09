import 'package:shared_preferences/shared_preferences.dart';

class App {
  static final App _app = App._();

  App._();

  factory App() => _app;

  static const String adbFilePathKey = "adbFilePathKey";
  static const String isShowSystemApp = 'isShowSystemApp';
  static const String scrcpyFilePathKey = "scrcpyFilePathKey";
  static const String saveFilePathKey = "saveFilePathKey";
  static const String appBackgroundKey = "appBackgroundKey";

  String _adbPath = "";

  String _scrcpyPath = "";

  String _appBackgroundPath = "";

  /// 保存ADB路径
  Future<void> setAdbPath(String path) async {
    _adbPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(adbFilePathKey, path);
  }

  /// 获取ADB缓存路径
  Future<String> getAdbPath() async {
    if (_adbPath.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _adbPath = prefs.getString(adbFilePathKey) ?? "";
    }
    return _adbPath;
  }

  /// 获取Scrcpy路径
  Future<String> getScrcpyPath() async {
    if (_scrcpyPath.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _scrcpyPath = prefs.getString(scrcpyFilePathKey) ?? "";
    }
    return _scrcpyPath;
  }

  /// 保存Scrcpy路径
  Future<void> setScrcpyPath(String path) async {
    _scrcpyPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(scrcpyFilePathKey, path);
  }

  /// 获取是否显示系统应用
  Future<bool> getIsShowSystemApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isShowSystemApp) ?? false;
  }

  /// 保存是否显示系统应用
  Future<void> setIsShowSystemApp(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isShowSystemApp, value);
  }

  /// 获取保存路径
  Future<String> getSaveFilePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(saveFilePathKey) ?? "";
  }

  /// 保存保存路径
  Future<void> setSaveFilePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(saveFilePathKey, path);
  }

  /// 获取应用背景路径
  Future<String> getAppBackgroundPath() async {
    if (_appBackgroundPath.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _appBackgroundPath = prefs.getString(appBackgroundKey) ?? "";
    }
    return _appBackgroundPath;
  }

  /// 保存应用背景路径
  Future<void> setAppBackgroundPath(String path) async {
    _appBackgroundPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appBackgroundKey, path);
  }
}
