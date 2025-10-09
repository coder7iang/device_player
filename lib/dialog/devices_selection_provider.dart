import 'package:device_player/dialog/devices_selection_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_player/dialog/devices_model.dart';



/// 设备选择状态管理器
class DevicesSelectionNotifier extends StateNotifier<DevicesSelectionState> {
  DevicesSelectionNotifier() : super(const DevicesSelectionState());

  /// 设置设备列表
  void setDevices(List<DevicesModel> devices) {
    state = state.copyWith(
      devicesList: devices,
      filteredDevicesList: devices,
    );
  }

  /// 设置选中设备
  void setSelectedDevice(DevicesModel? device) {
    state = state.copyWith(selectedDevice: device);
  }


  /// 清空设备列表
  void clearDevices() {
    state = state.copyWith(
      devicesList: [],
      filteredDevicesList: [],
      selectedDevice: null,
    );
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// 设置搜索文本并过滤设备
  void setSearchText(String searchText) {
    state = state.copyWith(searchText: searchText);
    _filterDevices();
  }

  /// 过滤设备列表
  void _filterDevices() {
    if (state.searchText.isEmpty) {
      state = state.copyWith(filteredDevicesList: state.devicesList);
    } else {
      // 将搜索文本按空格分割成多个关键词
      List<String> keywords = state.searchText
          .split(' ')
          .where((keyword) => keyword.isNotEmpty)
          .map((keyword) => keyword.toLowerCase())
          .toList();
      
      final filteredDevices = state.devicesList.where((device) {
        // 检查所有关键词是否都能在设备信息中找到
        return keywords.every((keyword) {
          String deviceInfo = "${device.brand} ${device.model} ${device.id}".toLowerCase();
          return deviceInfo.contains(keyword);
        });
      }).toList();
      
      state = state.copyWith(filteredDevicesList: filteredDevices);
    }
  }

  /// 刷新设备列表
  void refreshDevices(List<DevicesModel> devices) {
    setDevices(devices);
    _filterDevices();
  }
}

/// 设备选择的 Provider
final devicesSelectionProvider = StateNotifierProvider<DevicesSelectionNotifier, DevicesSelectionState>(
  (ref) => DevicesSelectionNotifier(),
);


