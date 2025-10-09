import 'package:device_player/entity/list_filter_item.dart';
import 'package:device_player/dialog/package_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class PackageListDialog extends ConsumerStatefulWidget {
  final List<ListFilterItem> data;
  final ListFilterItem? current;
  final Function()? refreshCallback;
  const PackageListDialog({
    required this.data,
    required this.current,
    this.refreshCallback,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PackageListDialog> createState() => _PackageListDialogState();
}

class _PackageListDialogState extends ConsumerState<PackageListDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(packageListProvider.notifier);
      notifier.setData(widget.data, current: widget.current);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 文本输入变化处理
  void _onTextChanged() {
    final notifier = ref.read(packageListProvider.notifier);
    notifier.filterData(_controller.text);
  }

 
  /// 创建高亮文本
  Widget _buildHighlightText(String text, String searchText) {
    if (searchText.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerSearchText = searchText.toLowerCase();
    final index = lowerText.indexOf(lowerSearchText);

    if (index == -1) {
      return Text(text);
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: const TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: text.substring(index, index + searchText.length),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.yellow,
            ),
          ),
          TextSpan(
            text: text.substring(index + searchText.length),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packageListProvider);
    final notifier = ref.read(packageListProvider.notifier);
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "请选择调试的应用包名",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    SmartDialog.dismiss();
                  },
                  icon: const Icon(Icons.close),
                  tooltip: "关闭",
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "搜索",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final items = state.selectorList.value;
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        "没有找到相关项",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = state.current?.itemTitle == item.itemTitle;
                      
                      return ListTile(
                        title: _buildHighlightText(item.itemTitle, _controller.text),
                        selected: isSelected,
                        onTap: () {
                          notifier.setCurrent(item);
                          SmartDialog.dismiss(result: item);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: state.isShowSystemApp,
                      onChanged: (value) {
                        if (value != null) {
                          notifier.setShowSystemApp(value);
                          widget.refreshCallback?.call();
                        }
                      },
                    ),
                    const Text("显示系统应用"),
                  ],
                ),
                const Spacer(), // 将刷新按钮推到右边
                IconButton(
                  onPressed: () {
                    widget.refreshCallback?.call();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: "刷新",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

