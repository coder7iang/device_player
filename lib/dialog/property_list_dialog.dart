import 'package:device_player/entity/list_filter_item.dart';
import 'package:device_player/dialog/property_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class PropertyListDialog extends ConsumerStatefulWidget {
  final List<ListFilterItem> data;
  const PropertyListDialog({
    required this.data,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PropertyListDialog> createState() => _PropertyListDialogState();
}

class _PropertyListDialogState extends ConsumerState<PropertyListDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(propertyListProvider.notifier);
      notifier.setData(widget.data);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 文本输入变化处理
  void _onTextChanged() {
    final notifier = ref.read(propertyListProvider.notifier);
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
    final state = ref.watch(propertyListProvider);
    final notifier = ref.read(propertyListProvider.notifier);
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
                    "系统属性列表",
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
                hintText: "请输入需要筛选的属性",
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
                        "没有找到相关属性",
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
          ],
        ),
      ),
    );
  }
}

