import 'package:desktop_drop/desktop_drop.dart';
import 'package:device_player/page/flie/file_manager_state.dart';
import 'package:device_player/page/flie/file_model.dart';
import 'package:device_player/services/adb_service.dart';
import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:device_player/common/app.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 文件管理页面的 Provider
final fileManagerProvider = StateNotifierProvider.family<FileManagerNotifier, FileManagerState, String>(
  (ref, deviceId) => FileManagerNotifier(deviceId),
);

/// 文件管理页面的状态管理器
class FileManagerNotifier extends StateNotifier<FileManagerState> {
  static const int typeFolder = 0;
  static const int typeFile = 1;
  static const int typeLinkFile = 2;
  static const int typeBackFolder = 2;
  
  FileManagerNotifier(String deviceId)
      : super(FileManagerState(deviceId: deviceId)) {
    // 初始化时获取文件列表
    getFileList();
  }

  /// 初始化
  Future<void> init() async {
    await getFileList();
  }
  
  /// 获取文件列表
  Future<void> getFileList() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      var result = await AdbService.instance.getFileList(state.currentPath);
      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "获取文件列表失败",
        );
        return;
      }
      
      List<FileModel> fileList = [];
      var stdout = result.stdout.toString().trim();
      var lines = stdout.isNotEmpty ? stdout.split('\n') : <String>[];
      
      for (var value in lines) {
        value = value.trim();
        if (value.isEmpty) continue;
        if (value.endsWith("/")) {
          fileList.add(FileModel(
            value.substring(0, value.length - 1),
            typeFolder,
            Icons.folder,
          ));
        } else if (value.endsWith("@")) {
          fileList.add(FileModel(
            value.substring(0, value.length - 1),
            typeLinkFile,
            Icons.attach_file,
          ));
        } else if (value.endsWith("*")) {
          fileList.add(FileModel(
            value.substring(0, value.length - 1),
            typeFile,
            Icons.insert_drive_file,
          ));
        } else {
          fileList.add(FileModel(
            value,
            typeFile,
            Icons.insert_drive_file,
          ));
        }
      }
      
      state = state.copyWith(
        files: fileList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "获取文件列表异常: $e",
      );
    }
  }
  
  /// 打开文件夹
  void openFolder(FileModel value) {
    if (value.type == typeFolder) {
      String newPath = state.currentPath + value.name + "/";
      state = state.copyWith(currentPath: newPath);
      getFileList();
    }
  }
  
  /// 返回上级文件夹
  void backFolder() {
    if (state.currentPath == state.rootPath) return;
    
    String newPath = state.currentPath.substring(
      0, 
      state.currentPath.lastIndexOf("/", state.currentPath.lastIndexOf("/") - 1) + 1
    );
    
    state = state.copyWith(currentPath: newPath);
    getFileList();
  }
  
  /// 处理拖拽完成
  void onDragDone(DropDoneDetails data, int index) async {
    if (index == -1 && state.isDragging) return;
    
    String devicePath = index == -1 
        ? state.currentPath 
        : state.currentPath + state.files[index].name;
    
    String msg = "";
    for (var file in data.files) {
      if (file.path.endsWith(".apk")) {
        // 安装 APK
        var success = await AdbService.instance.installApk(file.path);
        msg += "${file.name} ${success ? '安装成功' : '安装失败'}\n";
      } else {
        // 推送文件到设备
        var success = await AdbService.instance.pushFile(file.path, devicePath);
        msg += "${file.name} ${success ? '传输成功' : '传输失败'}\n";
      }
    }
    
    // 刷新文件列表
    await getFileList();
    
    SmartDialogUtils.showResult(content: msg);
    // 显示结果
  }
  
  /// 处理拖拽进入
  void onDragEntered(DropEventDetails data, int index) {
    state = state.copyWith(
      isDragging: true,
      selectedFileIndex: index,
    );
  }
  
  /// 处理拖拽离开
  void onDragExited(DropEventDetails data, int index) {
    state = state.copyWith(
      isDragging: false,
      selectedFileIndex: -1,
    );
  }
  
  /// 设置文件选择状态
  void setItemSelectState(int index, bool isSelect) {
    if (index >= 0 && index < state.files.length) {
      List<FileModel> newFiles = List.from(state.files);
      newFiles[index] = newFiles[index].copyWith(isSelect: isSelect);
      state = state.copyWith(files: newFiles);
    }
  }
  
  /// 推送文件到设备
  Future<String> pushFileToDevices(String filePath, String fileName, String devicePath) async {
    AdbService.instance.pushFile(filePath, devicePath);
    var success = await AdbService.instance.pushFile(filePath, devicePath);
    
    return success
        ? "$fileName 传输成功\n"
        : "$fileName 传输失败\n";
  }
  
  /// 删除文件
  Future<void> deleteFile(int index) async {
    if (index < 0 || index >= state.files.length) return;
    
    var success = await AdbService.instance.deleteFile(state.currentPath + state.files[index].name);
    
    
    if (success) {
      // 从列表中移除文件
      List<FileModel> newFiles = List.from(state.files);
      newFiles.removeAt(index);
      state = state.copyWith(files: newFiles);
      SmartDialogUtils.showSuccess("删除成功");
    } else {
      SmartDialogUtils.showError("删除失败");
    }
  }
  
  /// 保存文件到电脑
  Future<void> saveFile(int index) async {
    if (index < 0 || index >= state.files.length) return;
    
    // 尝试获取设置的保存路径
    final app = App();
    final setSavePath = await app.getSaveFilePath();
    String? savePath;
    
    if (setSavePath.isNotEmpty) {
      // 使用设置的保存路径
      savePath = setSavePath + "/" + state.files[index].name;
    } else {
      // 如果没有设置保存路径，让用户选择
      var saveLocation = await getSaveLocation(
        suggestedName: state.files[index].name
      );
      
      if (saveLocation == null) return;
      savePath = saveLocation.path;
    }
    
    if (savePath.isEmpty) {
      SmartDialogUtils.showError("无法获取文件保存路径");
      return;
    }
    
    var success = await AdbService.instance.pullFile(state.currentPath + state.files[index].name, savePath);
    
    if (success) {
      SmartDialogUtils.showSuccess("保存成功");
    } else {
      SmartDialogUtils.showError("保存失败");
    }
  }
  
  /// 刷新文件列表
  void refresh() {
    getFileList();
  }
  
  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  

  Future<void> onPointerDown(
      BuildContext context, PointerDownEvent event, int index) async {
    // 先选中文件
    setItemSelectState(index, true);

    // 等待长按时间（500ms）
    await Future.delayed(const Duration(milliseconds: 500));

    // 检查是否还在选中状态（简化处理，实际应该监听pointer up事件）
    if (state.files.length > index && state.files[index].isSelect) {
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      final menuItem = await showMenu<int>(
          context: context,
          items: [
            const PopupMenuItem(child: Text('删除'), value: 1),
            const PopupMenuItem(child: Text('保存至电脑'), value: 2),
          ],
          position: RelativeRect.fromSize(
              event.position & const Size(48.0, 48.0),
              overlay?.size ?? const Size(48.0, 48.0)));

      // 菜单关闭后取消选中状态
      setItemSelectState(index, false);

      switch (menuItem) {
        case 1:
          deleteFile(index);
          break;
        case 2:
          saveFile(index);
          break;
        default:
      }
    }
  }

  

}
