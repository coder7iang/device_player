import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:device_player/common/app.dart';
import 'package:device_player/common/key_code.dart';
import 'package:device_player/dialog/devices_model.dart';
import 'package:device_player/entity/list_filter_item.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell_run.dart';
import 'package:image/image.dart' as img;

/// ADB 服务类，封装所有 ADB 相关操作
class AdbService {
  static AdbService? _instance;
  static AdbService get instance => _instance ??= AdbService._();
  AdbService._();
  String adbPath = "";
  String currentDeviceId = "";
  String selectedPackage = "";
  
  

  /// 设置 ADB 路径
  setAdbPath(String path) {
    App().setAdbPath(path);
    adbPath = path;
  }

  /// 获取 ADB 路径
  _getAdbPath() async {
    String adbPath = await App().getAdbPath();
    if (adbPath.isNotEmpty && await File(adbPath).exists()) {
      this.adbPath = adbPath;
      return true;
    }
    return false;
  }


  /// 执行系统命令
  Future<dynamic> _exec(String executable, List<String> arguments) async {
    try {
      var shell = Shell();
      var result = await shell.runExecutableArguments(executable, arguments);
      return result;
    } catch (e) {
      debugPrint('执行命令异常: $e');
      return null;
    }
  }

  /// 执行 ADB 命令
  Future<ProcessResult?> _execAdb(List<String> arguments) async {
    try {
      var result = await _exec(adbPath, arguments);
      return result;
    } catch (e) {
      debugPrint('执行 ADB 命令异常: $e');
      return null;
    }
  }

  /// 获取adb路径
  checkAdb() async {
    bool hasAdb = await _getAdbPath();
    if (hasAdb) {
      return;
    }
    var executable = Platform.isWindows ? "where" : "which";
    var result = await _exec(executable, ['adb']);
    if (result != null && result.exitCode == 0) {
      adbPath = result.stdout.toString().trim();
      setAdbPath(adbPath);
      return;
    }
    adbPath = await downloadAdb();
    if (adbPath.isNotEmpty) {
      setAdbPath(adbPath);
    }
  }

  /// 下载 ADB 文件
  Future<String> downloadAdb() async {
    try {
      var directory = await getTemporaryDirectory();
      var downloadPath = directory.path +
          Platform.pathSeparator +
          "platform-tools" +
          Platform.pathSeparator;

      var url = "";
      if (Platform.isMacOS) {
        url =
            "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip";
      } else if (Platform.isWindows) {
        url =
            "https://dl.google.com/android/repository/platform-tools-latest-windows.zip";
      } else {
        url =
            "https://dl.google.com/android/repository/platform-tools-latest-linux.zip";
      }

      var filePath = downloadPath + "platform-tools-latest.zip";
      var response = await Dio().download(url, filePath);

      if (response.statusCode == 200) {
        String result = await unzipPlatformToolsFile(filePath);
        return result;
      }

      return "";
    } catch (e) {
      debugPrint('下载ADB失败: $e');
      return "";
    }
  }

  /// 解压 ADB zip 文件
  Future<String> unzipPlatformToolsFile(String unzipFilePath) async {
    try {
      var libraryDirectory = await getApplicationSupportDirectory();
      var savePath = libraryDirectory.path +
          Platform.pathSeparator +
          "adb" +
          Platform.pathSeparator;

      // 确保目录存在
      var directory = Directory(savePath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 尝试使用 archive 包解压
      try {
        var bytes = await File(unzipFilePath).readAsBytes();
        var archive = ZipDecoder().decodeBytes(bytes);
        extractArchiveToDisk(archive, savePath);
      } catch (e) {
        debugPrint('使用 archive 包解压失败，尝试使用系统命令: $e');
        // 如果 archive 包解压失败，尝试使用系统命令
        await _exec("rm", ["-rf", savePath]);
        await _exec("unzip", [unzipFilePath, "-d", savePath]);
        await _exec("rm", ["-rf", unzipFilePath]);
      }

      // 查找 adb 可执行文件
      var adbPath = "";
      if (Platform.isMacOS || Platform.isLinux) {
        adbPath = savePath + "platform-tools" + Platform.pathSeparator + "adb";
      } else if (Platform.isWindows) {
        adbPath =
            savePath + "platform-tools" + Platform.pathSeparator + "adb.exe";
      }

      if (await File(adbPath).exists()) {
        // 设置可执行权限
        if (Platform.isMacOS || Platform.isLinux) {
          await _exec("chmod", ["+x", adbPath]);
        }
        return adbPath;
      }

      return "";
    } catch (e) {
      debugPrint('解压ADB文件失败: $e');
      return "";
    }
  }

  /// 获取设备列表
  Future<List<DevicesModel>> getDeviceList() async {
    try {
      var result = await _execAdb(['devices']);
      if (result != null && result.exitCode == 0) {
        List<DevicesModel> devices = [];
        // 从 stdout 获取内容
        var stdout = result.stdout.toString().trim();
        if (stdout.isNotEmpty) {
          var lines = stdout.split('\n');
          for (var line in lines) {
            line = line.trim();
            if (line.isEmpty) continue;
            if (line.contains("List of devices attached")) {
              continue;
            }
            if (line.contains("device")) {
              var deviceLine = line.split("\t");
              if (deviceLine.length < 2) {
                deviceLine = line.split(" ");
              }
              if (deviceLine.isNotEmpty) {
                var device = deviceLine[0];
                var brand = await _getBrand(device);
                var model = await _getModel(device);
                devices.add(DevicesModel(brand, model, device));
              }
            }
          }
        }
        return devices;
      }
    } catch (e) {
      debugPrint('获取设备列表失败: $e');
    }
    return [];
  }

  /// 获取设备品牌
  Future<String> _getBrand(String device) async {
    try {
      var result = await _execAdb(
          ['-s', device, 'shell', 'getprop', 'ro.product.brand']);
      if (result != null && result.exitCode == 0) {
        var stdout = result.stdout.toString().trim();
        if (stdout.isNotEmpty) {
          return stdout;
        }
      }
      return device;
    } catch (e) {
      return device;
    }
  }

  /// 获取设备型号
  Future<String> _getModel(String device) async {
    try {
      var result = await _execAdb(
          ['-s', device, 'shell', 'getprop', 'ro.product.model']);
      if (result != null && result.exitCode == 0) {
        var stdout = result.stdout.toString().trim();
        if (stdout.isNotEmpty) {
          return stdout;
        }
      }
      return device;
    } catch (e) {
      return device;
    }
  }

  /// 安装 APK 到指定设备
  Future<bool> installApk(String apkPath) async {
    if (apkPath.isEmpty) return false;

    try {
      var result = await _execAdb([
        '-s',
        currentDeviceId,
        'install',
        '-r', // 重新安装
        '-d', // 允许降级
        apkPath
      ]);
      return result != null && result.exitCode == 0;
    } catch (e) {
      debugPrint('安装 APK 失败: $e');
      return false;
    }
  }

  /// 卸载应用
  Future<bool> uninstallApp(String packageName) async {
    if (packageName.isEmpty) return false;

    try {
      var result = await _execAdb(['-s', currentDeviceId, 'uninstall', packageName]);

      return result != null && result.exitCode == 0;
    } catch (e) {
      debugPrint('卸载应用失败: $e');
      return false;
    }
  }

  /// 获取已安装应用列表
  Future<List<ListFilterItem>> getInstalledApp() async {
    
    try {
      var isShowSysApp = await App().getIsShowSystemApp();
      var installedApp = await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'pm',
        'list',
        'packages',
        isShowSysApp ? '' : '-3',
      ]);
      
      if (installedApp == null) {
        return [];
      }
      
      var outLines = installedApp.outLines;
      var packageList = outLines.map((e) {
        return ListFilterItem(e.replaceAll("package:", ""));
      }).toList();
      
      packageList.sort((a, b) => a.itemTitle.compareTo(b.itemTitle));
      
      if (packageList.isNotEmpty) {
        selectedPackage = selectedPackage.isNotEmpty
            ? packageList
                .firstWhere(
                  (element) => element.itemTitle == selectedPackage,
                  orElse: () => packageList.first,
                )
                .itemTitle
            : packageList.first.itemTitle;
        
        return packageList;
      }

    } catch (e) {
      print('获取已安装应用失败: $e');
    }
    return [];
  }

  /// 输入文本到当前设备
  Future<bool> inputText(String text) async {
    if (text.isEmpty) return false;
    try {
      var result = await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'input',
        'text',
        text,
      ]);
      return result != null && result.exitCode == 0;
    } catch (e) {
      debugPrint('输入文本失败: $e');
      return false;
    }
  }

  /// 截图保存到电脑
  Future<bool> screenshot() async {
    try {
      String? savePath;
      
      // 优先使用设置的保存路径，如果没有设置则让用户选择
      final app = App();
      final setSavePath = await app.getSaveFilePath();
      if (setSavePath.isNotEmpty) {
        savePath = setSavePath;
      } else {
        // 如果没有设置保存路径，让用户选择
        savePath = await getDirectoryPath();
      }
      
      if (savePath == null || savePath.isEmpty) {
        debugPrint('无法获取截图保存路径');
        return false;
      }

      // 在设备上执行截图命令
      var screencapResult = await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'screencap',
        '-p',
        '/sdcard/screenshot.png',
      ]);

      if (screencapResult == null || screencapResult.exitCode != 0) {
        debugPrint('设备截图失败');
        return false;
      }

      // 生成本地文件名
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String localPath = '$savePath/screenshot_$timestamp.png';

      // 从设备拉取截图文件
      var pullResult = await _execAdb([
        '-s',
        currentDeviceId,
        'pull',
        '/sdcard/screenshot.png',
        localPath,
      ]);

      // 清理设备上的临时文件
      await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'rm',
        '-rf',
        '/sdcard/screenshot.png',
      ]);

      if (pullResult != null && pullResult.exitCode == 0) {
        // 添加水印
        await _addWatermark(localPath);
        debugPrint('截图保存成功: $localPath');
        return true;
      } else {
        debugPrint('拉取截图文件失败');
        return false;
      }
    } catch (e) {
      debugPrint('截图操作失败: $e');
      return false;
    }
  }

  /// 为截图添加水印
  Future<void> _addWatermark(String imagePath) async {
    try {
      // 读取图片文件
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('无法解码图片');
        return;
      }

      // 水印文字
      const watermarkText = 'screenshot by DevicePlayer';
      
      // 使用 arial48 字体（高度约48像素）
      final font = img.arial48;
      
      // 距离右边和底部的边距
      const margin = 20;
      
      // 计算文字位置（右下角）
      // arial48 字体，估算每个字符宽度约26像素
      const textWidth = watermarkText.length * 26;
      final textX = image.width - textWidth - margin;
      final textY = image.height - 48 - margin; // 48是字体高度
      
      // 先绘制黑色阴影（偏移2像素）增加可读性
      img.drawString(
        image,
        watermarkText,
        font: font,
        x: textX + 2,
        y: textY + 2,
        color: img.ColorRgba8(0, 0, 0, 200), // 黑色阴影
      );
      
      // 绘制白色文字
      img.drawString(
        image,
        watermarkText,
        font: font,
        x: textX,
        y: textY,
        color: img.ColorRgba8(255, 255, 255, 255), // 白色
      );
      
      // 保存图片
      final modifiedBytes = img.encodePng(image);
      await imageFile.writeAsBytes(modifiedBytes);
      
      debugPrint('水印添加成功');
    } catch (e) {
      debugPrint('添加水印失败: $e');
      // 即使添加水印失败，也不影响截图功能
    }
  }

  // 录屏相关
  Shell? _recordingShell;
  bool _isRecording = false;
  /// 录屏并保存到电脑
  Future<bool> recordScreen() async {
    if (_isRecording) return false;

    try {
      _recordingShell = Shell();
      _isRecording = true;
      
      // 异步启动录屏命令，不等待结果
      _recordingShell!.runExecutableArguments(adbPath, [
        '-s',
        currentDeviceId,
        'shell',
        'screenrecord',
        '/sdcard/screenrecord.mp4',
      ]).then((_) {
        // 命令正常结束（通常是被停止）
        debugPrint('录屏命令结束');
        _isRecording = false;
      }).catchError((e) {
        // 命令执行异常
        debugPrint('录屏命令执行异常: $e');
        _isRecording = false;
      });

      // 给命令一点启动时间，然后检查是否还在运行
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_isRecording) {
        debugPrint('录屏开始');
        return true;
      } else {
        debugPrint('录屏启动失败');
        return false;
      }
    } catch (e) {
      debugPrint('开始录屏失败: $e');
      _isRecording = false;
      return false;
    }
  }

  /// 停止录屏并保存
  Future<bool> stopRecordAndSave() async {
    if (!_isRecording) return false;

    try {
      // 停止录屏进程
      if (_recordingShell != null) {
        _recordingShell!.kill();
        _recordingShell = null;
      }
      _isRecording = false;

      // 等待一下确保文件写入完成
      await Future.delayed(const Duration(seconds: 1));

      String? savePath;
      
      // 优先使用设置的保存路径，如果没有设置则让用户选择
      final app = App();
      final setSavePath = await app.getSaveFilePath();
      if (setSavePath.isNotEmpty) {
        savePath = setSavePath;
      } else {
        // 如果没有设置保存路径，让用户选择
        savePath = await getDirectoryPath();
      }
      
      if (savePath == null || savePath.isEmpty) {
        debugPrint('无法获取录屏保存路径');
        return false;
      }

      // 生成本地文件名
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String localPath = '$savePath/screenrecord_$timestamp.mp4';

      // 从设备拉取录屏文件
      var pullResult = await _execAdb([
        '-s',
        currentDeviceId,
        'pull',
        '/sdcard/screenrecord.mp4',
        localPath,
      ]);

      // 清理设备上的临时文件
      await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'rm',
        '/sdcard/screenrecord.mp4',
      ]);

      if (pullResult != null && pullResult.exitCode == 0) {
        debugPrint('录屏保存成功: $localPath');
        return true;
      } else {
        debugPrint('拉取录屏文件失败');
        return false;
      }
    } catch (e) {
      debugPrint('停止录屏失败: $e');
      _isRecording = false;
      return false;
    }
  }

  /// 获取前台Activity
  Future<String?> getForegroundActivity() async {
    try {
      var result = await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'dumpsys',
        'activity',
        '|',
        'grep',
        'ResumedActivity',
      ]);

      if (result != null && result.exitCode == 0) {
        var stdout = result.stdout.toString().trim();

        if (stdout.isNotEmpty) {
          var lines = stdout.split('\n');
          for (var line in lines) {
            line = line.trim();
            // 处理 ResumedActivity 格式
            // 示例: topResumedActivity=ActivityRecord{6c44f05 u0 com.tencent.mm/.ui.LauncherUI t2353 d0}
            // 示例: ResumedActivity: ActivityRecord{6c44f05 u0 com.tencent.mm/.ui.LauncherUI t2353 d0}
            if (line.contains('ResumedActivity') && line.contains('u0 ')) {
              // 使用正则表达式提取包名/Activity名
              // 匹配格式: u0 包名/Activity名 (后面可能有空格和其他内容)
              var match = RegExp(r'u0\s+([^\s]+/[^\s]+)').firstMatch(line);
              if (match != null) {
                var activity = match.group(1)!;
                return activity;
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('获取前台Activity失败: $e');
      return null;
    }
  }

  /// 推送文件到设备
  Future<bool> pushFile(
      String localPath, String remotePath) async {
    if (localPath.isEmpty || remotePath.isEmpty) {
      return false;
    }

    try {
      var result =
          await _execAdb(['-s', currentDeviceId, 'push', localPath, remotePath]);

      return result != null && result.exitCode == 0;
    } catch (e) {
      debugPrint('推送文件失败: $e');
      return false;
    }
  }

  /// 从设备拉取文件
  Future<bool> pullFile(
      String remotePath, String localPath) async {
    if (remotePath.isEmpty || localPath.isEmpty) {
      return false;
    }

    try {
      var result =
          await _execAdb(['-s', currentDeviceId, 'pull', remotePath, localPath]);

      return result != null && result.exitCode == 0;
    } catch (e) {
      debugPrint('拉取文件失败: $e');
      return false;
    }
  }

  /// 测试ADB
  Future<bool> testAdb() async {
    try {
      var result = await _execAdb(['version']);
      return result != null && result.exitCode == 0;
    } catch (e) {
      debugPrint('测试ADB失败: $e');
      return false;
    }
  }

  /// 启动应用
  Future<bool> startApp() async {
    var launchActivity = await _getLaunchActivity();
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'am',
      'start',
      '-n',
      launchActivity,
    ]);
    return result != null && result.exitCode == 0;
  }

  /// 获取启动Activity
  Future<String> _getLaunchActivity() async {
    var launchActivity = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'dumpsys',
      'package',
      selectedPackage,
      '|',
      'grep',
      '-A',
      '1',
      'MAIN',
    ]);
    if (launchActivity == null) return "";
    var outLines = launchActivity.outLines;
    if (outLines.isEmpty) {
      return "";
    } else {
      for (var value in outLines) {
        if (value.contains("$selectedPackage/")) {
          return value.substring(
              value.indexOf("$selectedPackage/"), value.indexOf(" filter"));
        }
      }
      return "";
    }
  }

  /// 停止运行应用
  Future<bool> stopApp() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'am',
      'force-stop',
      selectedPackage,
    ]);
    return result != null && result.exitCode == 0;
  }

  /// 清除数据
  Future<bool> clearAppData() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'pm',
      'clear',
      selectedPackage,
    ]);
    return result != null && result.exitCode == 0;
  }

  /// 重置应用权限
  Future<void> resetAppPermission() async {
    var permissionList = await getAppPermissionList();
    for (var value in permissionList) {
      await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'pm',
        'revoke',
        selectedPackage,
        value,
      ]);
    }
  }

  /// 获取应用权限列表
  Future<List<String>> getAppPermissionList() async {
    var permission = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'dumpsys',
      'package',
      selectedPackage,
    ]);
    if (permission == null) return [];
    var outLines = permission.outLines;
    List<String> permissionList = [];
    for (var value in outLines) {
      if (value.contains("permission.")) {
        var permissionLine = value.replaceAll(" ", "").split(":");
        if (permissionLine.isEmpty) {
          continue;
        }
        var permission = permissionLine[0];
        permissionList.add(permission);
      }
    }
    return permissionList;
  }

  /// 授予应用权限
  Future<void> grantAppPermission() async {
    var permissionList = await getAppPermissionList();
    for (var value in permissionList) {
      await _execAdb([
        '-s',
        currentDeviceId,
        'shell',
        'pm',
        'grant',
        selectedPackage,
        value,
      ]);
    }
  }

  /// 获取应用安装路径
  Future<String> getAppInstallPath() async {
    var installPath = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'pm',
      'path',
      selectedPackage,
    ]);
    if (installPath == null || installPath.outLines.isEmpty) {
      return "";
    } else {
      var path = installPath.outLines.first.replaceAll("package:", "");
      return path;
    }
  }


  ///查看设备AndroidId
  Future<String> getAndroidId() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'settings',
      'get',
      'secure',
      'android_id',
    ]);

    var outLines = result?.outLines;
    if (outLines == null || outLines.isEmpty) {
      return "";
    } else {
      var androidId = outLines.first;
      return androidId;
    }
  }


  ///  查看设备系统版本
  Future<String> getDeviceVersion() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'getprop',
      'ro.build.version.release'
    ]);
    return result != null && result.exitCode == 0
        ? "Android " + result.stdout
        : '';
    
  }


  /// 查看设备IP地址
  Future<String> getDeviceIpAddress() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'ifconfig',
      '|',
      'grep',
      'Mask',
    ]);
    var outLines = result?.outLines;
    if (outLines == null || outLines.isEmpty) {
      return "";
    } else {
      var ip = "";
      for (var value in outLines) {
        value = value.substring(value.indexOf("addr:"), value.length);
        ip += value.substring(0, value.indexOf(" ")) + "\n";
        print(value);
      }
      return ip;
    }
  }

  /// 获取设备MAC地址
  Future<String> getDeviceMac() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      "ip addr show wlan0 | grep 'link/ether '| cut -d' ' -f6",
    ]);
    return result != null && result.exitCode == 0 ? result.stdout : "";
  }


  /// 重启手机
  Future<bool> reboot() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'reboot',
    ]);
    return result != null && result.exitCode == 0;
  }

  /// 查看系统属性
  Future<List<String>> getSystemProperty() async {
    var result = await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'getprop',
    ]);
    var outLines = result?.outLines;
    if (outLines == null || outLines.isEmpty) {
      return [];
    } else {
      var list = outLines.toList();
      list.sort((a, b) => a.compareTo(b));
      return list;
    }
  }

  /// Home键
  Future<void> pressHome() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '3',
    ]);
  }

  /// 返回键
  Future<void> pressBack() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '4',
    ]);
  }

  /// 菜单键
  Future<void> pressMenu() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '82',
    ]);
  }

  /// 增加音量
  Future<void> pressVolumeUp() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '24',
    ]);
  }

  /// 减少音量
  Future<void> pressVolumeDown() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '25',
    ]);
  }

  /// 静音
  Future<void> pressVolumeMute() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '164',
    ]);
  }

  /// 电源键
  Future<void> pressPower() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '26',
    ]);
  }

  /// 切换应用
  Future<void> pressSwitchApp() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      '187',
    ]);
  }

  /// 屏幕点击
  Future<void> pressScreen(String input) async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'tap',
      input.replaceAll(",", " "),
    ]);
  }

  /// 向上滑动
  Future<void> pressSwipeUp() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'swipe',
      '300',
      '1300',
      '300',
      '300',
    ]);
  }

  /// 向下滑动
  Future<void> pressSwipeDown() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'swipe',
      '300',
      '300',
      '300',
      '1300',
    ]);
  }

  /// 向左滑动
  Future<void> pressSwipeLeft() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'swipe',
      '900',
      '300',
      '100',
      '300',
    ]);
  }

  /// 向右滑动
  Future<void> pressSwipeRight() async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'swipe',
      '100',
      '300',
      '900',
      '300',
    ]);
  }

  /// 遥控器按键事件
  Future<void> pressRemoteKey(KeyCode keyCode) async {
    await _execAdb([
      '-s',
      currentDeviceId,
      'shell',
      'input',
      'keyevent',
      keyCode.value.toString(),
    ]);
  }


  /// 删除文件
  Future<bool> deleteFile(String path) async {
    var result = await _execAdb([
      "-s",
      currentDeviceId,
      "shell",
      "rm",
      "-rf",
      path
    ]);
    return result != null && result.exitCode == 0;
  }

  /// 获取文件列表
  Future<ProcessResult?> getFileList(String path) async {
    var processResult = await _execAdb([
      "-s",
      currentDeviceId,
      "shell",
      "ls",
      "-FA",
      path
    ]);
    return processResult;
  }

  /// 保存日志到电脑
  Future<bool> saveLog(String savePath, {String? packageName}) async {
    try {
      if (packageName == null || packageName.isEmpty) {
        print("需要指定包名来获取应用日志");
        return false;
      }
      
      // 获取应用外部存储的files/log目录路径
      String logDirPath = "/storage/emulated/0/Android/data/$packageName/files/log";
      
      // 检查日志目录是否存在
      var checkResult = await _execAdb([
        "-s",
        currentDeviceId,
        "shell",
        "ls",
        logDirPath
      ]);
      
      if (checkResult == null || checkResult.exitCode != 0) {
        print("应用日志目录不存在: $logDirPath");
        return false;
      }
      
      // 检查日志目录下是否有文件
      var listResult = await _execAdb([
        "-s",
        currentDeviceId,
        "shell",
        "find",
        logDirPath,
        "-type",
        "f"
      ]);
      
      if (listResult == null || listResult.exitCode != 0 || listResult.stdout.trim().isEmpty) {
        print("日志目录中没有找到文件");
        return false;
      }
      
      // 解析文件列表
      List<String> files = listResult.stdout.trim().split('\n')
          .where((String line) => line.trim().isNotEmpty)
          .toList();
      
      if (files.isEmpty) {
        print("没有找到文件");
        return false;
      }
      
      print("找到 ${files.length} 个文件，开始拉取日志目录...");
      
      // 使用adb pull拉取整个日志目录
      var success = await pullFile(logDirPath,savePath);
      
      if (success) {
        print("日志目录拉取成功");
        return true;
      } else {
        return false;
      }
      
    } catch (e) {
      print("保存日志失败: $e");
      return false;
    }
  }

}
