import 'package:device_player/dialog/devices_model.dart';
import 'package:device_player/dialog/devices_selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设备选择对话框
class DeviceSelectionDialog extends ConsumerStatefulWidget {
  final List<DevicesModel> devices;
  final List<DevicesModel> Function() getCurrentDevices;
  final DevicesModel? currentDevice;
  final Function()? refreshCallback;

  const DeviceSelectionDialog({
    Key? key,
    required this.devices,
    required this.getCurrentDevices,
    this.currentDevice,
    this.refreshCallback,
  }) : super(key: key);

  @override
  ConsumerState<DeviceSelectionDialog> createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends ConsumerState<DeviceSelectionDialog> {
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    
    // 初始化设备列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(devicesSelectionProvider.notifier).setDevices(widget.devices);
    });
    
    // 监听搜索输入
    searchController.addListener(() {
      ref.read(devicesSelectionProvider.notifier).setSearchText(searchController.text);
    });
  }

  /// 构建高亮文本
  List<TextSpan> _buildHighlightedText(String text, String searchText, TextStyle baseStyle) {
    if (searchText.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerSearchText = searchText.toLowerCase();
    int startIndex = 0;

    while (true) {
      int index = lowerText.indexOf(lowerSearchText, startIndex);
      if (index == -1) {
        // 添加剩余文本
        if (startIndex < text.length) {
          spans.add(TextSpan(
            text: text.substring(startIndex),
            style: baseStyle,
          ));
        }
        break;
      }

      // 添加匹配前的文本
      if (index > startIndex) {
        spans.add(TextSpan(
          text: text.substring(startIndex, index),
          style: baseStyle,
        ));
      }

      // 添加高亮匹配文本
      spans.add(TextSpan(
        text: text.substring(index, index + searchText.length),
        style: baseStyle.copyWith(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));

      startIndex = index + searchText.length;
    }

    return spans;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devicesSelectionProvider);
    final notifier = ref.read(devicesSelectionProvider.notifier);
    
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 400,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minHeight: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "选择设备",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "搜索设备",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: state.filteredDevicesList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.devicesList.isEmpty 
                                  ? "当前没有连接设备"
                                  : "没有找到相关设备",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            if (state.devicesList.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "请确保设备已连接并开启USB调试",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.filteredDevicesList.length,
                        itemBuilder: (context, index) {
                          final device = state.filteredDevicesList[index];
                          final isSelected = widget.currentDevice?.id == device.id;
                          
                          return ListTile(
                            title: RichText(
                              text: TextSpan(
                                children: _buildHighlightedText(
                                  "${device.brand} ${device.model}",
                                  state.searchText,
                                  TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                                children: _buildHighlightedText(
                                  device.id,
                                  state.searchText,
                                  TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withOpacity(0.1),
                            selectedColor: Colors.blue,
                            onTap: () {
                              Navigator.of(context).pop(device);
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("取消"),
                  ),
                  if (widget.refreshCallback != null)
                    TextButton(
                      onPressed: () async {
                        // 执行刷新回调
                        widget.refreshCallback!();
                        // 等待一下让设备列表更新
                        await Future.delayed(const Duration(milliseconds: 500));
                        // 获取最新的设备列表并更新UI
                        final newDevices = widget.getCurrentDevices();
                        notifier.refreshDevices(newDevices);
                      },
                      child: const Text("刷新"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}