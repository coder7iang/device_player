/// ADB 设置页面状态类
class SettingState {
  final String adbPath;
  final String scrcpyPath;
  final String saveFilePath;
  final String appBackgroundPath;

  const SettingState({
    this.adbPath = "",
    this.scrcpyPath = "",
    this.saveFilePath = "",
    this.appBackgroundPath = "",
  });

  /// 创建状态副本，支持部分更新
  SettingState copyWith({
    String? adbPath,
    String? scrcpyPath,
    String? saveFilePath,
    String? appBackgroundPath,
  }) {
    return SettingState(
      adbPath: adbPath ?? this.adbPath,
      scrcpyPath: scrcpyPath ?? this.scrcpyPath,
      saveFilePath: saveFilePath ?? this.saveFilePath,
      appBackgroundPath: appBackgroundPath ?? this.appBackgroundPath,
    );
  }

  /// 检查状态是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingState &&
        other.adbPath == adbPath &&
        other.scrcpyPath == scrcpyPath &&
        other.saveFilePath == saveFilePath &&
        other.appBackgroundPath == appBackgroundPath;
  }

  @override
  int get hashCode => adbPath.hashCode ^ scrcpyPath.hashCode ^ saveFilePath.hashCode ^ appBackgroundPath.hashCode;

  @override
  String toString() {
    return 'SettingState(adbPath: $adbPath, scrcpyPath: $scrcpyPath, saveFilePath: $saveFilePath, appBackgroundPath: $appBackgroundPath)';
  }
}
