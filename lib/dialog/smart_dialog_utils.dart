import 'package:device_player/services/adb_service.dart';
import 'package:device_player/dialog/confirm_dialog.dart';
import 'package:device_player/dialog/download_progress_dialog.dart';
import 'package:device_player/dialog/input_dialog.dart';
import 'package:device_player/entity/list_filter_item.dart';
import 'package:device_player/dialog/package_list_dialog.dart';
import 'package:device_player/dialog/property_list_dialog.dart';
import 'package:device_player/dialog/recording_dialog.dart';
import 'package:device_player/dialog/remote_control_dialog.dart';
import 'package:device_player/dialog/result_dialog.dart';
import 'package:device_player/dialog/coffee_reward_dialog.dart';
import 'package:device_player/dialog/food_roulette_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
/// SmartDialog 工具类
/// 封装常用的 Toast 和 Loading 功能
class SmartDialogUtils {
  SmartDialogUtils._();

  /// 显示成功提示
  static void showSuccess(String message) {
    SmartDialog.showToast(
      message,
      alignment: Alignment.center,
      displayTime: const Duration(seconds: 2),
      builder: (context) => _buildToastContainer(
        message: message,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      ),
    );
  }

  /// 显示错误提示
  static void showError(String message) {
    SmartDialog.showToast(
      message,
      alignment: Alignment.center,
      displayTime: const Duration(seconds: 3),
      builder: (context) => _buildToastContainer(
        message: message,
        icon: Icons.error,
        iconColor: Colors.red,
      ),
    );
  }

  /// 显示警告提示
  static void showWarning(String message) {
    SmartDialog.showToast(
      message,
      alignment: Alignment.center,
      displayTime: const Duration(seconds: 2),
      builder: (context) => _buildToastContainer(
        message: message,
        icon: Icons.warning,
        iconColor: Colors.orange,
      ),
    );
  }

  /// 显示信息提示
  static void showInfo(String message) {
    SmartDialog.showToast(
      message,
      alignment: Alignment.center,
      displayTime: const Duration(seconds: 2),
      builder: (context) => _buildToastContainer(
        message: message,
        icon: Icons.info,
        iconColor: Colors.blue,
      ),
    );
  }

  /// 显示普通 Toast
  static void showToast(String message, {
    Duration? duration,
    Alignment? alignment,
  }) {
    SmartDialog.showToast(
      message,
      alignment: alignment ?? Alignment.center,
      displayTime: duration ?? const Duration(seconds: 2),
      builder: (context) => _buildToastContainer(message: message),
    );
  }

  /// 显示加载中对话框
  static void showLoading([String? message]) {
    SmartDialog.showLoading(
      msg: message ?? '加载中...',
      builder: (context) => _buildLoadingContainer(message ?? '加载中...'),
    );
  }



  /// 隐藏加载中对话框
  static void hideLoading() {
    SmartDialog.dismiss();
  }



  /// 显示确认对话框
  static Future<bool> showConfirm({
    String? title,
    String? content,
  }) async {
    bool? result = await SmartDialog.show(
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
      ),
    );
    return result ?? false;
  }

  /// 显示确认对话框
  static Future<bool> showResult({
    String? title,
    String? content,
  }) async {
    bool? result = await SmartDialog.show(
      builder: (context) => ResultDialog(
        title: title,
        content: content,
      ),
    );
    return result ?? false;
  }

  /// 显示输入对话框
  static Future<String?> showInput({
    required String title,
    String hintText = '请输入内容',
  }) async {
    String? result = await SmartDialog.show<String>(
      builder: (context) => InputDialog(
        title: title,
        hintText: hintText,
      ),
    );
    return result;
  }

  /// 构建 Toast 容器
  static Widget _buildToastContainer({
    required String message,
    IconData? icon,
    Color? iconColor,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载中容器
  static Widget _buildLoadingContainer(
    String message, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }


  

  /// 显示录屏计时对话框
  static void showRecordingDialog({
    required VoidCallback onStop,
  }) {
    SmartDialog.show(
      builder: (context) => RecordingDialog(onStop: onStop),
      backType: SmartBackType.block,
      clickMaskDismiss: false,
    );
  }

  /// 隐藏录屏计时对话框
  static void hideRecordingDialog() {
    SmartDialog.dismiss();
  }

  /// 显示选择对话框
  static Future<ListFilterItem?> showPackageListDialog(List<ListFilterItem> data,
    ListFilterItem? current, Function()? refreshCallback) async {
    
    ListFilterItem result = await SmartDialog.show(
      builder: (context) => PackageListDialog(data: data, current: current, refreshCallback: refreshCallback),
      clickMaskDismiss: true,
    );

    return result;
  }


  static Future<ListFilterItem?> showPropertyListDialog(List<ListFilterItem> data) async {
    
    ListFilterItem result = await SmartDialog.show(
      builder: (context) => PropertyListDialog(data: data),
      clickMaskDismiss: true,
    );

    return result;

  }

  static Future<void> showRemoteControlDialog() async {
    SmartDialog.show(
      builder: (context) => RemoteControlDialog(onTap: AdbService.instance.pressRemoteKey,),
      clickMaskDismiss: true,
    );
  }

  static Future<String?> showInputDialog({
    String title = "输入文本",
    String hintText = "输入文本",
  }) async {
    return await SmartDialog.show(
      builder: (context) => InputDialog(
        title: title,
        hintText: hintText,
      ),
      clickMaskDismiss: true,
    );
  }


  /// 显示下载进度对话框
  static Future<bool> showDownloadProgress({
    required String url,
    required String path,
  }) async {
    // 显示对话框
    var success = await SmartDialog.show(
      tag: 'download_progress',
      builder: (context) => DownloadProgressDialog(url: url, path: path),
      clickMaskDismiss: false,
    );
    return success;
    
  }

  /// 显示咖啡奖励弹窗
  static Future<void> showCoffeeReward() async {
    await SmartDialog.show(
      builder: (context) => const CoffeeRewardDialog(),
      clickMaskDismiss: true,
      backType: SmartBackType.block,
    );
  }

  /// 显示食物轮盘弹窗
  static Future<void> showFoodRoulette() async {
    await SmartDialog.show(
      builder: (context) => const FoodRouletteDialog(),
      clickMaskDismiss: true,
      backType: SmartBackType.block,
    );
  }
}
