import 'package:device_player/entity/list_filter_item.dart';
import 'package:selector_plus/selector_plus.dart';

/// 列表过滤状态类
class PackageListState {
  final SelectorListPlusData<ListFilterItem> selectorList;
  final List<ListFilterItem> dataList;
  final ListFilterItem? current;
  final bool isShowSystemApp;
  final bool isLoading;

  const PackageListState({
    required this.selectorList,
    required this.dataList,
    this.current,
    this.isShowSystemApp = false,
    this.isLoading = false,
  });

  PackageListState copyWith({
    SelectorListPlusData<ListFilterItem>? selectorList,
    List<ListFilterItem>? dataList,
    ListFilterItem? current,
    bool? isShowSystemApp,
    bool? isLoading,
  }) {
    return PackageListState(
      selectorList: selectorList ?? this.selectorList,
      dataList: dataList ?? this.dataList,
      current: current ?? this.current,
      isShowSystemApp: isShowSystemApp ?? this.isShowSystemApp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PackageListState &&
        other.selectorList == selectorList &&
        other.dataList == dataList &&
        other.current == current &&
        other.isShowSystemApp == isShowSystemApp &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return selectorList.hashCode ^
        dataList.hashCode ^
        current.hashCode ^
        isShowSystemApp.hashCode ^
        isLoading.hashCode;
  }

  @override
  String toString() {
    return 'PackageListState(selectorList: $selectorList, dataList: $dataList, current: $current, isShowSystemApp: $isShowSystemApp, isLoading: $isLoading)';
  }
}
