import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_player/common/app.dart';
import 'package:device_player/page/log/android_log_state.dart';
import 'package:device_player/services/adb_service.dart';
import 'package:device_player/entity/list_filter_item.dart';
import 'package:device_player/dialog/package_list_provider.dart';
import 'package:device_player/widget/pop_up_menu_button.dart';
import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日志页面的 Provider
final androidLogProvider = StateNotifierProvider.family<AndroidLogNotifier, AndroidLogState, String>(
  (ref, deviceId) => AndroidLogNotifier(deviceId),
);

/// 日志页面的状态管理器
class AndroidLogNotifier extends StateNotifier<AndroidLogState> {
  String? get adbPath => state.adbPath;
  
  /// 筛选级别 ViewModel
  late PopUpMenuButtonViewModel<FilterLevel> filterLevelViewModel;
  
  /// 筛选内容控制器
  late TextEditingController filterController;
  
  /// 查找控制器
  late TextEditingController findController;
  
  /// 滚动控制器
  late FlutterListViewController scrollController;

  List<FilterLevel> filterLevel = [
    FilterLevel("Verbose", "*:V"),
    FilterLevel("Debug", "*:D"),
    FilterLevel("Info", "*:I"),
    FilterLevel("Warn", "*:W"),
    FilterLevel("Error", "*:E"),
  ];
  
  /// 执行 ADB 命令
  Future<dynamic> execAdb(List<String> arguments) async {
    if (adbPath == null || adbPath!.isEmpty) {
      state = state.copyWith(errorMessage: "ADB没有找到，请配置ADB环境变量");
      return null;
    }
    
    try {
      // 打印完整的命令行
      String command = '$adbPath ${arguments.join(' ')}';
      debugPrint('执行 ADB 命令: $command');
      
      var process = await Process.run(adbPath!, arguments);
      return process;
    } catch (e) {
      state = state.copyWith(errorMessage: "执行ADB命令失败: $e");
      return null;
    }
  }
  
  /// 设置 ADB 路径
  void setAdbPath(String path) {
    state = state.copyWith(adbPath: path);
  }
  
  static const String colorLogKey = 'colorLog';
  static const String caseSensitiveKey = 'caseSensitive';
  
  Process? _process;
  final List<String> _pendingLogs = [];  // 待更新的日志缓冲区
  Timer? _updateTimer;  // 用于批量更新的定时器
  
  AndroidLogNotifier(String deviceId) 
      : super(AndroidLogState(deviceId: deviceId)) {
    // 初始化控制器
    filterLevelViewModel = PopUpMenuButtonViewModel<FilterLevel>();
    filterLevelViewModel.list = filterLevel;
    filterLevelViewModel.selectValue = filterLevel.first;
    filterController = TextEditingController();
    findController = TextEditingController();
    scrollController = FlutterListViewController();
    
    
    // 启动批量更新定时器（每200ms更新一次）
    _startBatchUpdateTimer();
    
    // 监听查找输入框，清空时重置查找索引
    findController.addListener(() {
      if (findController.text.isEmpty) {
        if (state.findIndex >= 0) {
          state = state.copyWith(findIndex: -1);
        }
      }
    });
    
    // 初始化时加载设置并开始监听日志
    _loadSettings();
    _initLogging();
  }
  

  
  /// 启动批量更新定时器
  void _startBatchUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_pendingLogs.isNotEmpty) {
        _flushPendingLogs();
      }
    });
  }
  
  /// 批量更新日志到状态
  void _flushPendingLogs() {
    if (_pendingLogs.isEmpty) return;
    
    List<String> updatedLogs = List.from(state.logList)..addAll(_pendingLogs);
    
    // 限制日志数量，避免内存溢出
    if (updatedLogs.length > 1000) {
      updatedLogs = updatedLogs.sublist(updatedLogs.length - 1000);
    }
    
    state = state.copyWith(logList: updatedLogs);
    _pendingLogs.clear();
    
    
  }
  
  /// 初始化
  Future<void> init() async {
    await _loadSettings();
    await _initLogging();
  }
  
  /// 选择包名
  Future<void> selectPackageName(BuildContext context, WidgetRef ref) async {
    // 这里应该显示包名选择对话框
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
    
    if (selectedPackage != null) {
      state = state.copyWith(
        packageName: selectedPackage.itemTitle,
        logList: [],  // 清除现有日志
      );
      
      bool pidSuccess = await _getPid();
      
      if (!pidSuccess) {
        // PID 获取失败，显示提示并恢复到无选中状态
        SmartDialogUtils.showError(
          '应用 "${selectedPackage.itemTitle}" 未运行或无法获取进程信息，请确保应用正在运行'
        );
        
        // 恢复到无选中状态
        state = state.copyWith(
          packageName: "",
          pid: "",
          logList: [],
        );
        _restartLogListener();
      } else {
        // PID 获取成功，重启监听器并筛选
        _restartLogListener();
      }
    }
  }
  
  /// 清除包名筛选
  void clearPackageName() {
    state = state.copyWith(
      packageName: "",
      pid: "",
      logList: [],  // 清除现有日志
    );
    _restartLogListener();  // 重启监听器显示所有日志
  }
  
  /// 加载用户设置
  Future<void> _loadSettings() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      bool isCaseSensitive = preferences.getBool(caseSensitiveKey) ?? false;
      
      state = state.copyWith(
        isCaseSensitive: isCaseSensitive,
      );
    } catch (e) {
      // 设置加载失败，使用默认值
    }
  }
  
  /// 初始化日志监听
  Future<void> _initLogging() async {
    if (state.deviceId.isEmpty) return;
    
    // 获取 ADB 路径
    String path = await App().getAdbPath();
    setAdbPath(path);
    
    await _getInstalledApps();
    await _getPid();
    await _clearLog();
    await _startLogListener();
  }
  
  /// 获取已安装应用列表
  Future<void> _getInstalledApps() async {
    try {
      var result = await execAdb([
        '-s', 
        state.deviceId, 
        'shell', 
        'pm', 
        'list', 
        'packages', 
        '-3'
      ]);
      
      if (result != null && result.exitCode == 0) {
        List<String> apps = [];
        String output = result.stdout.toString();
        List<String> lines = output.split('\n');
        for (var line in lines) {
          if (line.startsWith('package:')) {
            apps.add(line.replaceFirst('package:', '').trim());
          }
        }
        
        state = state.copyWith(installedApps: apps);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: "获取应用列表失败: $e");
    }
  }
  
  /// 获取应用 PID
  Future<bool> _getPid() async {
    if (state.packageName.isEmpty) return false;
    
    try {
      var result = await execAdb([
        '-s', 
        state.deviceId, 
        'shell', 
        'pidof', 
        state.packageName
      ]);
      
      if (result != null && result.exitCode == 0) {
        String output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          debugPrint('获取到 PID: $output (包名: ${state.packageName})');
          state = state.copyWith(pid: output);
          return true;
        } else {
          debugPrint('PID 为空，应用可能未运行 (包名: ${state.packageName})');
          state = state.copyWith(pid: "");
          return false;
        }
      } else {
        debugPrint('获取 PID 失败，exitCode: ${result?.exitCode}');
        state = state.copyWith(pid: "");
        return false;
      }
    } catch (e) {
      debugPrint('获取 PID 异常: $e');
      state = state.copyWith(pid: "");
      return false;
    }
  }


  
  /// 清除日志
  Future<void> _clearLog() async {
    try {
      await execAdb([
        '-s', 
        state.deviceId, 
        'logcat', 
        '-c'
      ]);
    } catch (e) {
      // 清除日志失败，继续执行
    }
  }
  
  /// 开始监听日志
  Future<void> _startLogListener() async {
    if (state.isLogging) return;
    
    state = state.copyWith(isLogging: true);
    
    try {
      List<String> args = [
        '-s', 
        state.deviceId, 
        'logcat',
        state.selectedFilterLevel
      ];
      
      // 根据 PID 过滤应用日志（有包名就自动筛选）
      if (state.pid.isNotEmpty) {
        args.add('--pid=${state.pid}');
        debugPrint('当前 PID: ${state.pid}, 包名: ${state.packageName}');
      }
      
      // 打印完整的命令行
      String command = '${adbPath ?? 'adb'} ${args.join(' ')}';
      debugPrint('执行 ADB 命令: $command');
      
      _process = await Process.start(adbPath ?? 'adb', args);
      
      _process!.stdout.transform(utf8.decoder).listen((data) {
        _processLogData(data);
      });
      
      _process!.stderr.transform(utf8.decoder).listen((data) {
        // 处理错误输出
      });
      
      _process!.exitCode.then((code) {
        state = state.copyWith(isLogging: false);
      });
      
    } catch (e) {
      state = state.copyWith(
        isLogging: false,
        errorMessage: "启动日志监听失败: $e",
      );
    }
  }
  
  /// 处理日志数据
  void _processLogData(String data) {
    List<String> lines = data.split('\n');
    
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      // 应用内容筛选（只在有筛选内容时才过滤）
      if (state.filterContent.isNotEmpty) {
        String logText = state.isCaseSensitive ? line : line.toLowerCase();
        String filterText = state.isCaseSensitive ? state.filterContent : state.filterContent.toLowerCase();
        if (logText.contains(filterText)) {
          _pendingLogs.add(line);
        }
      } else {
        _pendingLogs.add(line);
      }
    }
    
    // 不再立即更新状态，而是添加到缓冲区，由定时器批量更新
  }
  
  /// 设置包名
  void setPackageName(String packageName) {
    state = state.copyWith(packageName: packageName);
    _getPid();
    _restartLogListener();
  }
  
  /// 设置筛选内容
  void setFilterContent(String content) {
    state = state.copyWith(filterContent: content);
    _applyFilter();
  }
  
  /// 设置筛选级别
  void setFilterLevel(String level) {
    state = state.copyWith(selectedFilterLevel: level);
    _restartLogListener();
  }
  
  /// 设置是否区分大小写
  void setCaseSensitive(bool value) async {
    state = state.copyWith(isCaseSensitive: value);
    
    // 保存设置
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setBool(caseSensitiveKey, value);
    } catch (e) {
      // 保存失败
    }
    
    _applyFilter();
  }
  

  
  /// 滚动到底部
  void scrollToBottom() {
    // 启用自动滚动到底部
    
    // 启用自动跟随最新日志
    state = state.copyWith(isShowLast: true);
    
    // 立即滚动到底部
    try {
      scrollController.jumpTo(
        scrollController.position.maxScrollExtent,
      );
    } catch (e) {
      // 如果滚动失败，尝试稍后再试
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          scrollController.jumpTo(
            scrollController.position.maxScrollExtent,
          );
        } catch (e) {
          // 忽略错误
        }
      });
    }
  }
  
  /// 应用筛选
  void _applyFilter() {
    if (state.filterContent.isEmpty) return;
    
    List<String> filteredLogs = state.logList.where((log) {
      String logText = state.isCaseSensitive ? log : log.toLowerCase();
      String filterText = state.isCaseSensitive ? state.filterContent : state.filterContent.toLowerCase();
      return logText.contains(filterText);
    }).toList();
    
    state = state.copyWith(logList: filteredLogs);
  }
  
  /// 查找下一个
  void findNext() {
    if (state.logList.isEmpty || findController.text.isEmpty) return;
    
    // 获取所有匹配项索引
    List<int> allMatches = _getAllMatchIndices();
    if (allMatches.isEmpty) return;
    
    // 找到下一个匹配项
    int currentPosition = state.findIndex >= 0 
        ? allMatches.indexOf(state.findIndex) 
        : -1;
    
    int nextPosition = currentPosition + 1;
    if (nextPosition >= allMatches.length) {
      nextPosition = 0;  // 循环到第一个
    }
    
    int foundIndex = allMatches[nextPosition];
    
    state = state.copyWith(
      findIndex: foundIndex,
    );
    
    // 滚动到找到的位置
    try {
      scrollController.sliverController.jumpToIndex(
        foundIndex,
        offsetBasedOnBottom: true,
      );
    } catch (e) {
      // 滚动失败，忽略
    }
  }
  
  /// 查找上一个
  void findPrevious() {
    if (state.logList.isEmpty || findController.text.isEmpty) return;
    
    // 获取所有匹配项索引
    List<int> allMatches = _getAllMatchIndices();
    if (allMatches.isEmpty) return;
    
    // 找到上一个匹配项
    int currentPosition = state.findIndex >= 0 
        ? allMatches.indexOf(state.findIndex) 
        : allMatches.length;
    
    int prevPosition = currentPosition - 1;
    if (prevPosition < 0) {
      prevPosition = allMatches.length - 1;  // 循环到最后一个
    }
    
    int foundIndex = allMatches[prevPosition];
    
    state = state.copyWith(
      findIndex: foundIndex,
    );
    
    // 滚动到找到的位置
    try {
      scrollController.sliverController.jumpToIndex(
        foundIndex,
        offsetBasedOnBottom: true,
      );
    } catch (e) {
      // 滚动失败，忽略
    }
  }
  
  /// 获取所有匹配项的索引列表
  List<int> _getAllMatchIndices() {
    String searchText = findController.text;
    if (searchText.isEmpty) return [];
    
    List<int> matchIndices = [];
    for (int i = 0; i < state.logList.length; i++) {
      String log = state.logList[i];
      String logText = state.isCaseSensitive ? log : log.toLowerCase();
      String findText = state.isCaseSensitive ? searchText : searchText.toLowerCase();
      if (logText.contains(findText)) {
        matchIndices.add(i);
      }
    }
    return matchIndices;
  }
  
  /// 复制日志
  void copyLog(String log) {
    Clipboard.setData(ClipboardData(text: log));
  }
  
  /// 清除日志
  void clearLog() {
    state = state.copyWith(
      logList: [],
      findIndex: -1,
    );
  }
  
  /// 停止日志监听
  void stopLogListener() {
    if (_process != null) {
      _process!.kill();
      _process = null;
    }
    state = state.copyWith(isLogging: false);
  }
  
  /// 重启日志监听
  void _restartLogListener() {
    stopLogListener();
    _startLogListener();
  }
  
  /// 刷新应用列表
  Future<void> refreshApps() async {
    await _getInstalledApps();
  }
  
  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();  // 取消定时器
    _pendingLogs.clear();  // 清空缓冲区
    stopLogListener();
    filterController.dispose();
    findController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
