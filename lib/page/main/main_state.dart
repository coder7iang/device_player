import 'package:device_player/dialog/devices_model.dart';

/// 主页面状态类
class MainState {
  final String adbPath;
  final List<DevicesModel> devicesList;
  final DevicesModel? selectedDevice;
  final int selectedIndex;
  final bool isLoading;
  final String loadingText;
  final String? errorMessage;
  final bool isAdbAvailable;
  
  const MainState({
    this.adbPath = "",
    this.devicesList = const [],
    this.selectedDevice,
    this.selectedIndex = 1,
    this.isLoading = false,
    this.loadingText = "",
    this.errorMessage,
    this.isAdbAvailable = false,
  });
  
  /// 创建状态副本，支持部分更新
  MainState copyWith({
    String? adbPath,
    List<DevicesModel>? devicesList,
    DevicesModel? selectedDevice,
    int? selectedIndex,
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
    bool? isAdbAvailable,
    clearSelectedDevice = false,
  }) {
    return MainState(
      adbPath: adbPath ?? this.adbPath,
      devicesList: devicesList ?? this.devicesList,
      selectedDevice: clearSelectedDevice 
        ? null 
        : (selectedDevice ?? this.selectedDevice),
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isLoading: isLoading ?? this.isLoading,
      loadingText: loadingText ?? this.loadingText,
      errorMessage: errorMessage ?? this.errorMessage, // 使用 ?? 操作符保持原有值
      isAdbAvailable: isAdbAvailable ?? this.isAdbAvailable,
    );
  }
  
  /// 获取当前选中的设备ID
  String get deviceId => selectedDevice?.id ?? "";
  
  /// 获取当前选中的包名
  String get packageName => ""; // 暂时返回空字符串，后续可以从全局状态获取
  
  /// 检查状态是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MainState &&
        other.adbPath == adbPath &&
        other.devicesList == devicesList &&
        other.selectedDevice == selectedDevice &&
        other.selectedIndex == selectedIndex &&
        other.isLoading == isLoading &&
        other.loadingText == loadingText &&
        other.errorMessage == errorMessage &&
        other.isAdbAvailable == isAdbAvailable;
  }
  
  @override
  int get hashCode => Object.hash(
    adbPath, 
    devicesList, 
    selectedDevice, 
    selectedIndex, 
    isLoading, 
    loadingText, 
    errorMessage, 
    isAdbAvailable
  );
  
  @override
  String toString() {
    return 'MainState(adbPath: $adbPath, devicesList: ${devicesList.length}, selectedDevice: $selectedDevice, selectedIndex: $selectedIndex, isLoading: $isLoading, loadingText: $loadingText, errorMessage: $errorMessage, isAdbAvailable: $isAdbAvailable)';
  }
}