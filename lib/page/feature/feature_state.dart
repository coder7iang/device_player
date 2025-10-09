import 'package:flutter/material.dart';

/// 功能页面状态类
class FeatureState {
  final String deviceId;
  final String packageName;
  final bool isRecording;
  
  const FeatureState({
    required this.deviceId,
    this.packageName = "",
    this.isRecording = false,
  });
  
  /// 创建状态副本，支持部分更新
  FeatureState copyWith({
    String? deviceId,
    String? packageName,
    bool? isRecording,
  }) {
    return FeatureState(
      deviceId: deviceId ?? this.deviceId,
      packageName: packageName ?? this.packageName,
      isRecording: isRecording ?? this.isRecording,
    );
  }
  
  /// 检查状态是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeatureState &&
        other.deviceId == deviceId &&
        other.packageName == packageName &&
        other.isRecording == isRecording;
  }
  
  @override
  int get hashCode => Object.hash(
    deviceId, 
    packageName, 
    isRecording, 
  );
  
  @override
  String toString() {
    return 'FeatureState(deviceId: $deviceId, packageName: $packageName, isRecording: $isRecording)';
  }

  /// 获取功能按钮颜色
  Color getColor(String title) {
    switch (title) {
      case "安装应用":
        return Colors.blue;
      case "输入文本":
        return Colors.green;
      case "截图保存到电脑":
        return Colors.orange;
      case "查看当前Activity":
        return Colors.purple;
      case "卸载应用":
        return Colors.red;
      case "启动应用":
        return Colors.teal;
      case "停止运行":
        return Colors.indigo;
      case "重启应用":
        return Colors.cyan;
      case "清除数据":
        return Colors.brown;
      case "重置权限":
        return Colors.deepOrange;
      case "授权所有权限":
        return Colors.lightBlue;
      case "查看应用安装路径":
        return Colors.lime;
      case "保存应用APK到电脑":
        return Colors.amber;
      case "开始录屏":
        return Colors.deepPurple;
      case "结束录屏保存到电脑":
        return Colors.pink;
      case "查看AndroidId":
        return Colors.blueGrey;
      case "查看系统版本":
        return Colors.lightGreen;
      case "查看IP地址":
        return Colors.deepOrange;
      case "查看Mac地址":
        return Colors.indigo;
      case "重启手机":
        return Colors.red;
      case "查看系统属性":
        return Colors.teal;
      case "HOME键":
        return Colors.blue;
      case "返回键":
        return Colors.green;
      case "菜单键":
        return Colors.orange;
      case "电源键":
        return Colors.red;
      case "增加音量":
        return Colors.blue;
      case "降低音量":
        return Colors.green;
      case "静音":
        return Colors.grey;
      case "切换应用":
        return Colors.purple;
      case "遥控器":
        return Colors.teal;
      case "向上滑动":
        return Colors.blue;
      case "向下滑动":
        return Colors.green;
      case "向左滑动":
        return Colors.orange;
      case "向右滑动":
        return Colors.purple;
      case "屏幕点击":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
