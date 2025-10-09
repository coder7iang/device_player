import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:device_player/common/app.dart';
import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell_run.dart';

class ScrcpyService {
  static ScrcpyService? _instance;
  static ScrcpyService get instance => _instance ??= ScrcpyService._();
  ScrcpyService._();
  String scrcpyPath = "";

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

  /// 设置文件执行权限（跨平台）
  Future<bool> setFileExecutablePermission(String filePath) async {
    if (Platform.isWindows) {
      // Windows 不需要设置执行权限
      debugPrint('Windows 系统无需设置文件执行权限: $filePath');
      return true;
    }
    
    try {
      if (filePath.isEmpty || !await File(filePath).exists()) {
        debugPrint('文件不存在，无法设置权限: $filePath');
        return false;
      }
      
      debugPrint('设置文件执行权限: $filePath');
      var chmodResult = await _exec("chmod", ['+x', filePath]);
      
      if (chmodResult != null && chmodResult.exitCode == 0) {
        debugPrint('设置文件执行权限成功: $filePath');
        return true;
      } else {
        debugPrint('设置文件执行权限失败: $filePath, 错误: ${chmodResult?.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('设置文件执行权限时出错: $e');
      return false;
    }
  }

  /// 检查 scrcpy 是否存在
  checkScrcpy() async {
    bool hasScrcpy = await getScrcpyPath();
    if (hasScrcpy) {
      debugPrint('已找到 scrcpy: $scrcpyPath');
      return;
    }
    // 检查系统中是否已安装 scrcpy
    var executable = Platform.isWindows ? "where" : "which";
    try {
      var result = await _exec(executable, ['scrcpy']);
      if (result != null && result.exitCode == 0) {
        scrcpyPath = result.stdout.toString().trim();
        await setScrcpyPath(scrcpyPath);
        debugPrint('系统中找到 scrcpy: $scrcpyPath');
        return;
      }
    } catch (e) {
      debugPrint('检查系统中 scrcpy 失败: $e');
    }
    // 系统中没有找到 scrcpy，尝试下载
    debugPrint('系统中未找到 scrcpy，开始下载...');
    scrcpyPath = await downloadScrcpy();
    if (scrcpyPath.isNotEmpty) {
      await setScrcpyPath(scrcpyPath);
      debugPrint('scrcpy 下载成功: $scrcpyPath');
    } else {
      debugPrint('scrcpy 下载失败');
    }
  }

  /// 获取 Scrcpy 路径
  getScrcpyPath() async {  
    String scrcpyPath = await App().getScrcpyPath();
    if (scrcpyPath.isNotEmpty && await File(scrcpyPath).exists()) {
      this.scrcpyPath = scrcpyPath;
      await _ensureScrcpyPermissions(scrcpyPath);
      return true;
    }
    return false;
  }

  /// 设置 Scrcpy 路径
  setScrcpyPath(String path) async {
    App().setScrcpyPath(path);
    scrcpyPath = path;
    // 设置路径后自动设置执行权限
    if (path.isNotEmpty) {
      await _ensureScrcpyPermissions(path);
    }
  }

  /// 测试 Scrcpy 连接
  testScrcpy() async {
    // 首先检查并修复权限
    await _ensureScrcpyPermissions(scrcpyPath);
    
    var result = await _exec(scrcpyPath, ['-v']);
    return result != null && result.exitCode == 0;
  }

  /// 统一设置 scrcpy 相关文件的执行权限

  Future<bool> _ensureScrcpyPermissions(String scrcpyPath) async {
    try {
      if (scrcpyPath.isEmpty || !await File(scrcpyPath).exists()) {
        debugPrint('scrcpy 文件不存在，无法设置权限: $scrcpyPath');
        return false;
      }

      debugPrint('开始设置 scrcpy 相关文件权限...');
      bool allSuccess = true;

      // 1. 设置 scrcpy 执行权限
      debugPrint('检查 scrcpy 权限: $scrcpyPath');
      bool scrcpySuccess = await setFileExecutablePermission(scrcpyPath);
      if (!scrcpySuccess) {
        debugPrint('❌ 设置 scrcpy 权限失败');
        allSuccess = false;
      } else {
        debugPrint('✅ 设置 scrcpy 权限成功');
      }

      // 2. 查找并设置 adb 权限
      try {
        var libraryDirectory = await getApplicationSupportDirectory();
        var scrcpyDir = '${libraryDirectory.path}${Platform.pathSeparator}scrcpy${Platform.pathSeparator}';
        var adbPath = await _findAdbExecutable(scrcpyDir);
        
        if (adbPath.isNotEmpty) {
          debugPrint('检查 adb 权限: $adbPath');
          bool adbSuccess = await setFileExecutablePermission(adbPath);
          if (!adbSuccess) {
            debugPrint('❌ 设置 adb 权限失败');
            allSuccess = false;
          } else {
            debugPrint('✅ 设置 adb 权限成功');
          }
        } else {
          debugPrint('⚠️ 未找到 adb 文件，跳过权限设置');
        }
      } catch (e) {
        debugPrint('❌ 设置 adb 权限时出错: $e');
        allSuccess = false;
      }

      if (allSuccess) {
        debugPrint('✅ 所有权限设置成功');
      } else {
        debugPrint('⚠️ 部分权限设置失败');
      }

      return allSuccess;
    } catch (e) {
      debugPrint('❌ 设置 scrcpy 权限时出错: $e');
      return false;
    }
  }

  /// 解压 ADB zip 文件
  Future<String> unzipScrcpyFile(String unzipFilePath) async {
    try {
      var libraryDirectory = await getApplicationSupportDirectory();
      var savePath = libraryDirectory.path +
          Platform.pathSeparator +
          "scrcpy" +
          Platform.pathSeparator;

      // 确保目录存在
      var directory = Directory(savePath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 根据文件类型选择解压方法
      var fileName = unzipFilePath.split(Platform.pathSeparator).last;
      debugPrint('开始解压文件: $fileName');
      
      if (fileName.endsWith('.zip')) {
        // Windows ZIP 文件
        try {
          var bytes = await File(unzipFilePath).readAsBytes();
          var archive = ZipDecoder().decodeBytes(bytes);
          extractArchiveToDisk(archive, savePath);
          debugPrint('使用 archive 包解压 ZIP 成功');
        } catch (e) {
          debugPrint('使用 archive 包解压 ZIP 失败，尝试使用系统命令: $e');
          if (Platform.isWindows) {
            await _exec("powershell", ["-Command", "Expand-Archive -Path '$unzipFilePath' -DestinationPath '$savePath' -Force"]);
          } else {
            await _exec("unzip", ["-o", unzipFilePath, "-d", savePath]);
          }
        }
      } else if (fileName.endsWith('.tar.gz')) {
        // macOS/Linux TAR.GZ 文件 - 直接使用系统命令解压
        try {
          debugPrint('使用系统命令解压 TAR.GZ 文件: $unzipFilePath');
          var result = await _exec("tar", ["-xzf", unzipFilePath, "-C", savePath]);
          debugPrint('系统命令解压结果: ${result?.exitCode}');
          if (result?.exitCode == 0) {
            debugPrint('使用系统命令解压 TAR.GZ 成功');
          } else {
            debugPrint('系统命令解压失败，错误: ${result?.stderr}');
            throw Exception('系统命令解压失败: ${result?.stderr}');
          }
        } catch (e) {
          debugPrint('系统命令解压失败，尝试使用 archive 包: $e');
          try {
            var bytes = await File(unzipFilePath).readAsBytes();
            debugPrint('读取压缩文件成功，大小: ${bytes.length} bytes');
            
            // 先用 GZipDecoder 解压 gzip
            var gzipBytes = GZipDecoder().decodeBytes(bytes);
            debugPrint('GZip 解压成功，大小: ${gzipBytes.length} bytes');
            
            // 再用 TarDecoder 解压 tar
            var archive = TarDecoder().decodeBytes(gzipBytes);
            debugPrint('Tar 解码成功，包含 ${archive.files.length} 个文件');
            
            // 打印所有文件信息
            for (var file in archive.files) {
              debugPrint('  - ${file.name} (大小: ${file.size} bytes)');
            }
            
            extractArchiveToDisk(archive, savePath);
            debugPrint('使用 archive 包解压 TAR.GZ 成功，解压到: $savePath');
          } catch (e2) {
            debugPrint('archive 包解压也失败: $e2');
            rethrow;
          }
        }
      } else {
        debugPrint('不支持的文件格式: $fileName');
        return "";
      }

      debugPrint('解压scrcpy文件成功: $savePath');
      
      // 检查解压后的目录内容
      var extractDir = Directory(savePath);
      if (await extractDir.exists()) {
        await _printDirectoryTree(extractDir, '解压后目录内容详情');
      }
      
      // 清理下载的压缩文件
      try {
        await File(unzipFilePath).delete();
        debugPrint('已删除压缩文件: $unzipFilePath');
      } catch (e) {
        debugPrint('删除压缩文件失败: $e');
      }

      // 查找 scrcpy 可执行文件
      var scrcpyPath = await _findScrcpyExecutable(savePath);
      if (scrcpyPath.isNotEmpty) {
        debugPrint('找到 scrcpy 可执行文件: $scrcpyPath');
        return scrcpyPath;
      }

      debugPrint('未找到 scrcpy 可执行文件');
      return "";
    } catch (e) {
      debugPrint('解压ADB文件失败: $e');
      return "";
    }
  }

  /// 查找 scrcpy 可执行文件
  Future<String> _findScrcpyExecutable(String basePath) async {
    try {
      var directory = Directory(basePath);
      if (!await directory.exists()) {
        debugPrint('❌ 目录不存在: $basePath');
        return "";
      }

      // 先打印目录结构
      await _printDirectoryTree(directory, '开始查找 scrcpy 可执行文件', recursive: true);
      
      // 获取所有子目录和文件
      var entities = await directory.list(recursive: true).toList();
      
      List<String> scrcpyCandidates = [];
      List<String> allFiles = [];
      
      for (var entity in entities) {
        if (entity is File) {
          var name = entity.path.split(Platform.pathSeparator).last;
          allFiles.add(name);
          
          // 查找 scrcpy 文件
          if (name == 'scrcpy') {
            scrcpyCandidates.add(entity.path);
          }
        }
      }
      
      // 显示查找结果
      debugPrint('📋 所有文件列表: ${allFiles.join(', ')}');
      debugPrint('🎯 scrcpy 候选文件: ${scrcpyCandidates.length} 个');
      
      if (scrcpyCandidates.isNotEmpty) {
        for (int i = 0; i < scrcpyCandidates.length; i++) {
          debugPrint('   ${i + 1}. ${scrcpyCandidates[i]}');
        }
        debugPrint('✅ 找到 scrcpy 可执行文件: ${scrcpyCandidates.first}');
        return scrcpyCandidates.first;
      }
      
      debugPrint('❌ 未找到 scrcpy 可执行文件');
      debugPrint('💡 提示: 请检查解压后的文件结构是否正确');
      return "";
    } catch (e) {
      debugPrint('❌ 查找 scrcpy 可执行文件失败: $e');
      return "";
    }
  }

  

  /// 查找 adb 可执行文件
  Future<String> _findAdbExecutable(String basePath) async {
    try {
      var directory = Directory(basePath);
      if (!await directory.exists()) {
        return "";
      }

      // 获取所有子目录和文件
      var entities = await directory.list(recursive: true).toList();
      
      for (var entity in entities) {
        if (entity is File) {
          var fileName = entity.path.split(Platform.pathSeparator).last;
          if (fileName == 'adb' || fileName == 'adb.exe') {
            debugPrint('找到 adb 文件: ${entity.path}');
            return entity.path;
          }
        }
      }
      
      return "";
    } catch (e) {
      debugPrint('查找 adb 可执行文件失败: $e');
      return "";
    }
  }

  /// 启动投屏
  Future<bool> startMirroring() async {
    try {
      // 确保 scrcpy 可用
      await checkScrcpy();
      if (scrcpyPath.isEmpty) {
        debugPrint('scrcpy 不可用');
        return false;
      }
      
      // 启动 scrcpy 投屏
      var result = await _exec(scrcpyPath, []);
      return result != null && result.exitCode == 0;
    } catch (e) {
      debugPrint('启动投屏失败: $e');
      return false;
    }
  }

  /// 下载 ADB 文件
  Future<String> downloadScrcpy() async {
    try {
      var directory = await getTemporaryDirectory();
      var downloadPath = directory.path +
          Platform.pathSeparator +
          "scrcpy" +
          Platform.pathSeparator;

      var url = "";
      if (Platform.isMacOS) {
        url =
            "https://coder7iang.oss-cn-beijing.aliyuncs.com/scrcpy-macos-aarch64-v3.3.2.tar.gz";
        // url =
        //     "https://github.com/Genymobile/scrcpy/releases/download/v3.3.2/scrcpy-macos-aarch64-v3.3.2.tar.gz";
      } else if (Platform.isWindows) {
        url =
            "https://github.com/Genymobile/scrcpy/releases/download/v3.3.2/scrcpy-win64-v3.3.2.zip";
      } else {
        url =
            "https://github.com/Genymobile/scrcpy/releases/download/v3.3.2/scrcpy-linux-x86_64-v3.3.2.tar.gz";
      }

      var filePath = downloadPath + "scrcpy-latest.tar.gz";
      
      // 显示下载进度对话框
      var success = await SmartDialogUtils.showDownloadProgress(
        url: url,
        path: filePath,
      );

      if (success) {
        String result = await unzipScrcpyFile(filePath);
        debugPrint('下载scrcpy成功: $result');
        return result;
      }
      debugPrint('下载scrcpy失败: $success');

      return "";
    } catch (e) {
      debugPrint('下载scrcpy失败: $e');
      SmartDialogUtils.showError('下载scrcpy失败: $e');
      return "";
    }
  }

  /// 打印目录文件列表（树形结构）
  /// [directory] 要打印的目录
  /// [title] 打印标题
  /// [recursive] 是否递归显示子目录
  Future<void> _printDirectoryTree(Directory directory, String title, {bool recursive = false}) async {
    try {
      if (!await directory.exists()) {
        debugPrint('❌ 目录不存在: ${directory.path}');
        return;
      }

      debugPrint('\n🔍 ========== $title ==========');
      debugPrint('📂 目录: ${directory.path}');
      
      var entities = recursive 
          ? await directory.list(recursive: true).toList()
          : await directory.list().toList();
      
      debugPrint('📊 统计: ${entities.length} 个文件/目录');
      debugPrint('┌─────────────────────────────────────────────────────────────┐');
      
      if (recursive) {
        // 递归模式：显示所有文件
        for (var entity in entities) {
          var icon = entity is File ? '📄' : '📁';
          var name = entity.path.split(Platform.pathSeparator).last;
          var relativePath = entity.path.replaceFirst(directory.path, '');
          var type = entity is File ? '文件' : '目录';
          
          debugPrint('├── $icon $name ($type)');
          debugPrint('│   └── 路径: $relativePath');
        }
      } else {
        // 非递归模式：树形结构显示
        for (int i = 0; i < entities.length; i++) {
          var entity = entities[i];
          var name = entity.path.split(Platform.pathSeparator).last;
          var isLast = i == entities.length - 1;
          var prefix = isLast ? '└── ' : '├── ';
          var icon = entity is File ? '📄' : '📁';
          var type = entity is File ? '文件' : '目录';
          debugPrint('$prefix$icon $name ($type)');
          
          // 如果是目录，也检查其内容
          if (entity is Directory) {
            try {
              var subEntities = await entity.list().toList();
              var subPrefix = isLast ? '    ' : '│   ';
              debugPrint('$subPrefix└── 子目录内容 (${subEntities.length} 个):');
              for (int j = 0; j < subEntities.length; j++) {
                var subEntity = subEntities[j];
                var subName = subEntity.path.split(Platform.pathSeparator).last;
                var subIcon = subEntity is File ? '📄' : '📁';
                var subIsLast = j == subEntities.length - 1;
                var subItemPrefix = subIsLast ? '    └── ' : '    ├── ';
                debugPrint('$subItemPrefix$subIcon $subName');
              }
            } catch (e) {
              debugPrint('    └── ❌ 无法访问子目录: $e');
            }
          }
        }
      }
      
      debugPrint('└─────────────────────────────────────────────────────────────┘');
      debugPrint('🔍 ========== $title 结束 ==========\n');
    } catch (e) {
      debugPrint('❌ 打印目录树失败: $e');
    }
  }
}