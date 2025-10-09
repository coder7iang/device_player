import 'package:device_player/common/app.dart';
import 'package:device_player/entity/list_filter_item.dart';
import 'package:device_player/dialog/package_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selector_plus/selector_plus.dart';

/// 列表过滤的 Provider
final packageListProvider = StateNotifierProvider<PackageListProvider, PackageListState>(
  (ref) => PackageListProvider(),
);

/// 列表过滤状态管理器
class PackageListProvider extends StateNotifier<PackageListState> {
  PackageListProvider() : super(PackageListState(
    selectorList: SelectorListPlusData<ListFilterItem>(),
    dataList: [],
    current: null,
    isShowSystemApp: false,
    isLoading: false,
  ));

  /// 设置数据
  void setData(List<ListFilterItem> data, {ListFilterItem? current}) {
    if (current != null) {
      state = state.copyWith(current: current);
    }
    // 显示所有数据
    final newSelectorList = state.selectorList..value = data;
    state = state.copyWith(dataList: data, selectorList: newSelectorList);
  }

  /// 过滤数据
  void filterData(String searchText) {
    if (searchText.isEmpty) {
      state = state.copyWith(
        selectorList: state.selectorList..value = state.dataList,
      );
      return;
    }
    
    var filteredList = state.dataList
        .where((element) => element.itemTitle.contains(searchText))
        .toList();
    
    state = state.copyWith(
      selectorList: state.selectorList..value = filteredList,
    );
  }

  /// 设置是否显示系统应用
  Future<void> setShowSystemApp(bool value) async {
    state = state.copyWith(isShowSystemApp: value);
    await App().setIsShowSystemApp(value);
  }


  /// 设置当前选中项
  void setCurrent(ListFilterItem? current) {
    state = state.copyWith(current: current);
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// 刷新数据
  void refresh() {
    // 显示所有数据
    state = state.copyWith(
      selectorList: state.selectorList..value = state.dataList,
    );
  }
}
