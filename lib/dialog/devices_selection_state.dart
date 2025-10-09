import 'package:device_player/dialog/devices_model.dart';

/// 设备选择状态
class DevicesSelectionState {
  final List<DevicesModel> devicesList;
  final List<DevicesModel> filteredDevicesList;
  final DevicesModel? selectedDevice;
  final bool isLoading;
  final String searchText;

  const DevicesSelectionState({
    this.devicesList = const [],
    this.filteredDevicesList = const [],
    this.selectedDevice,
    this.isLoading = false,
    this.searchText = '',
  });

  DevicesSelectionState copyWith({
    List<DevicesModel>? devicesList,
    List<DevicesModel>? filteredDevicesList,
    DevicesModel? selectedDevice,
    bool? isLoading,
    String? searchText,
  }) {
    return DevicesSelectionState(
      devicesList: devicesList ?? this.devicesList,
      filteredDevicesList: filteredDevicesList ?? this.filteredDevicesList,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      isLoading: isLoading ?? this.isLoading,
      searchText: searchText ?? this.searchText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DevicesSelectionState &&
        other.devicesList == devicesList &&
        other.filteredDevicesList == filteredDevicesList &&
        other.selectedDevice == selectedDevice &&
        other.isLoading == isLoading &&
        other.searchText == searchText;
  }

  @override
  int get hashCode {
    return devicesList.hashCode ^
        filteredDevicesList.hashCode ^
        selectedDevice.hashCode ^
        isLoading.hashCode ^
        searchText.hashCode;
  }

  @override
  String toString() {
    return 'DevicesSelectionState(devicesList: $devicesList, filteredDevicesList: $filteredDevicesList, selectedDevice: $selectedDevice, isLoading: $isLoading, searchText: $searchText)';
  }
}