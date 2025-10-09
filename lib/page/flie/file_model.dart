import 'package:flutter/material.dart';

class FileModel {
  String name;
  int type;
  IconData? icon;
  bool isSelect;

  FileModel(this.name, this.type, this.icon, {this.isSelect = false});
  
  /// 创建文件模型副本，支持部分更新
  FileModel copyWith({
    String? name,
    int? type,
    IconData? icon,
    bool? isSelect,
  }) {
    return FileModel(
      name ?? this.name,
      type ?? this.type,
      icon ?? this.icon,
      isSelect: isSelect ?? this.isSelect,
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
        other.isSelect == isSelect;
  }
  
  @override
  int get hashCode => Object.hash(name, type, icon, isSelect);
  
  @override
  String toString() {
    return 'FileModel(name: $name, type: $type, icon: $icon, isSelect: $isSelect)';
  }
}
