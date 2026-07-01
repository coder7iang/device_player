import 'package:flutter/material.dart';

class FileModel {
  String name;
  int type;
  IconData? icon;
  bool isSelect;

  /// 文件大小（字节）。文件夹或未知为 -1
  int size;

  /// 修改时间，形如 "2024-03-10 15:17"。未知为空字符串
  String modifiedTime;

  FileModel(
    this.name,
    this.type,
    this.icon, {
    this.isSelect = false,
    this.size = -1,
    this.modifiedTime = '',
  });

  /// 把字节数格式化为易读字符串（B/KB/MB/GB）
  String get sizeText {
    if (size < 0) return '';
    if (size < 1024) return '$size B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    double s = size / 1024;
    int i = 0;
    while (s >= 1024 && i < units.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(s >= 100 ? 0 : 1)} ${units[i]}';
  }

  /// 创建文件模型副本，支持部分更新
  FileModel copyWith({
    String? name,
    int? type,
    IconData? icon,
    bool? isSelect,
    int? size,
    String? modifiedTime,
  }) {
    return FileModel(
      name ?? this.name,
      type ?? this.type,
      icon ?? this.icon,
      isSelect: isSelect ?? this.isSelect,
      size: size ?? this.size,
      modifiedTime: modifiedTime ?? this.modifiedTime,
    );
  }

  /// 检查文件模型是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileModel &&
        other.name == name &&
        other.type == type &&
        other.icon == icon &&
        other.isSelect == isSelect &&
        other.size == size &&
        other.modifiedTime == modifiedTime;
  }

  @override
  int get hashCode => Object.hash(name, type, icon, isSelect, size, modifiedTime);

  @override
  String toString() {
    return 'FileModel(name: $name, type: $type, icon: $icon, isSelect: $isSelect, size: $size, modifiedTime: $modifiedTime)';
  }
}
