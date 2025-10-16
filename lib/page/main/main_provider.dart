import 'package:device_player/common/app.dart';
import 'package:device_player/dialog/devices_model.dart';
import 'package:device_player/dialog/devices_selection_dialog.dart';
import 'package:device_player/page/main/main_state.dart';
import 'package:device_player/services/adb_service.dart';
import 'package:device_player/services/scrcpy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主页面的 Provider
final mainProvider = StateNotifierProvider<MainNotifier, MainState>(
  (ref) => MainNotifier(),
);

/// 主页面的状态管理器
class MainNotifier extends StateNotifier<MainState> {
  MainNotifier() : super(const MainState()) {
    // 初始化时检查 ADB 并获取设备列表
    init();
  }

  /// 初始化
  Future<void> init() async {
    await checkAdb();
    await checkScrcpy();
    if (state.isAdbAvailable) {
      await getDeviceList();
    }
  }
  
  /// 检查 Scrcpy 是否可用
  Future<void> checkScrcpy() async {
    await ScrcpyService.instance.getScrcpyPath();
  }

  /// 检查 ADB 是否可用
  Future<void> checkAdb() async {
    await AdbService.instance.checkAdb();
    String adbPath = await App().getAdbPath();
    state = state.copyWith(
      adbPath: adbPath,
      isAdbAvailable: adbPath.isNotEmpty,
    );
  }

  /// 获取设备列表
  Future<void> getDeviceList() async {
    if (!state.isAdbAvailable) {
      return;
    }
    state = state.copyWith(isLoading: true, loadingText: "获取设备列表中...");
    try {
      var devices = await AdbService.instance.getDeviceList();
      if (devices.isNotEmpty) {
        state = state.copyWith(
          devicesList: devices,
          selectedDevice: devices.first,
          selectedIndex: 1, // 设置默认页面为 FeaturePage
          isLoading: false,
          loadingText: "",
        );
      } else {
        state = state.copyWith(
          devicesList: [],
          selectedDevice: null,
          clearSelectedDevice: true,
          selectedIndex: 1, // 没有设备时也保持显示 FeaturePage
          isLoading: false,
          loadingText: "",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingText: "",
        errorMessage: "获取设备列表异常: $e",
      );
    }
    if (state.selectedDevice != null) {
      AdbService.instance.currentDeviceId = state.selectedDevice!.id;
    }
  }

  /// 选择设备
  void selectDevice(int index) {
    if (index >= 0 && index < state.devicesList.length) {
      state = state.copyWith(
        selectedIndex: index,
        selectedDevice: state.devicesList[index],
      );
    }
  }

  /// 选择页面
  void selectPage(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  /// 选择设备
  Future<void> devicesSelect(BuildContext context) async {
    await getDeviceList();
    
    var value = await showDialog<DevicesModel>(
      context: context,
      builder: (context) => DeviceSelectionDialog(
        devices: state.devicesList,
        getCurrentDevices: () => state.devicesList,
        currentDevice: state.selectedDevice,
        refreshCallback: () async {
          await getDeviceList();
          state = state.copyWith();
        },
      ),
    );

    if (value != null) {
      int deviceIndex =
          state.devicesList.indexWhere((device) => device.id == value.id);
      if (deviceIndex != -1) {
        state = state.copyWith(
          selectedDevice: value,
          selectedIndex: 1, // 选择设备后自动切换到功能页面
        );
      }
    }
  }
}