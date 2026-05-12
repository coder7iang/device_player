import 'package:device_player/page/flie/file_model.dart';

/// 文件管理页面状态类
class FileManagerState {
  final String deviceId;
  final String currentPath;
  final String rootPath;
  final List<FileModel> files;
  final bool isLoading;
  final bool isDragging;
  final String? errorMessage;
  final int selectedFileIndex;
  /// 非空 = 当前处于 App 私有目录浏览模式，文件操作走 run-as <pkg>
  final String? runAsPackage;

  const FileManagerState({
    required this.deviceId,
    this.currentPath = '/sdcard/',
    this.rootPath = '/sdcard/',
    this.files = const [],
    this.isLoading = false,
    this.isDragging = false,
    this.errorMessage,
    this.selectedFileIndex = -1,
    this.runAsPackage,
  });

  /// 创建状态副本，支持部分更新
  /// runAsPackage 用 sentinel 来允许显式置为 null（退出私有模式）
  static const _sentinel = Object();
  FileManagerState copyWith({
    String? deviceId,
    String? currentPath,
    String? rootPath,
    List<FileModel>? files,
    bool? isLoading,
    bool? isDragging,
    String? errorMessage,
    int? selectedFileIndex,
    Object? runAsPackage = _sentinel,
  }) {
    return FileManagerState(
      deviceId: deviceId ?? this.deviceId,
      currentPath: currentPath ?? this.currentPath,
      rootPath: rootPath ?? this.rootPath,
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      isDragging: isDragging ?? this.isDragging,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedFileIndex: selectedFileIndex ?? this.selectedFileIndex,
      runAsPackage: identical(runAsPackage, _sentinel)
          ? this.runAsPackage
          : runAsPackage as String?,
    );
  }
  
  /// 检查状态是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileManagerState &&
        other.deviceId == deviceId &&
        other.currentPath == currentPath &&
        other.rootPath == rootPath &&
        other.files == files &&
        other.isLoading == isLoading &&
        other.isDragging == isDragging &&
        other.errorMessage == errorMessage &&
        other.selectedFileIndex == selectedFileIndex &&
        other.runAsPackage == runAsPackage;
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    currentPath,
    rootPath,
    files,
    isLoading,
    isDragging,
    errorMessage,
    selectedFileIndex,
    runAsPackage,
  );

  @override
  String toString() {
    return 'FileManagerState(deviceId: $deviceId, currentPath: $currentPath, rootPath: $rootPath, files: ${files.length}, isLoading: $isLoading, isDragging: $isDragging, errorMessage: $errorMessage, selectedFileIndex: $selectedFileIndex, runAsPackage: $runAsPackage)';
  }
}
