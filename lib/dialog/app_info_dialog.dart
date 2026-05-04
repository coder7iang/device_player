import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:device_player/entity/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class AppInfoDialog extends StatelessWidget {
  final AppInfo info;
  final String packageName;

  const AppInfoDialog({
    Key? key,
    required this.info,
    required this.packageName,
  }) : super(key: key);

  List<_InfoField> _buildFields() {
    return [
      _InfoField('版本名', info.versionName),
      _InfoField('版本号', info.versionCode),
      _InfoField('compileSdk', info.compileSdk),
      _InfoField('targetSdk', info.targetSdk),
      _InfoField('minSdk', info.minSdk),
    ].where((e) => e.value.isNotEmpty).toList();
  }

  String _buildAllText(List<_InfoField> fields) {
    final buf = StringBuffer();
    buf.writeln('包名: $packageName');
    for (final f in fields) {
      buf.writeln('${f.label}: ${f.value}');
    }
    if (info.permissions.isNotEmpty) {
      buf.writeln('权限列表 (${info.permissions.length}):');
      for (final p in info.permissions) {
        buf.writeln('  ${p.name}${p.granted ? ' [已授予]' : ''}');
      }
    }
    return buf.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final fields = _buildFields();
    final permissions = info.permissions;
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '应用信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => SmartDialog.dismiss(),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                '包名: $packageName',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...List.generate(fields.length * 2 - (fields.isEmpty ? 0 : 1), (i) {
                      if (i.isOdd) return const Divider(height: 1);
                      return _InfoRow(field: fields[i ~/ 2]);
                    }),
                    if (permissions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Text(
                          '权限列表 (${permissions.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ...List.generate(permissions.length * 2 - 1, (i) {
                        if (i.isOdd) return const Divider(height: 1);
                        return _PermissionRow(permission: permissions[i ~/ 2]);
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _buildAllText(fields)),
                    );
                    SmartDialogUtils.showSuccess('已复制全部信息');
                  },
                  icon: const Icon(Icons.copy_all, size: 18),
                  label: const Text('全部复制'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => SmartDialog.dismiss(),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField {
  final String label;
  final String value;

  _InfoField(this.label, this.value);
}

class _InfoRow extends StatelessWidget {
  final _InfoField field;

  const _InfoRow({Key? key, required this.field}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              field.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              field.value,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: field.value));
              SmartDialogUtils.showSuccess('已复制 ${field.label}');
            },
            icon: const Icon(Icons.copy, size: 16),
            tooltip: '复制',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final AppPermission permission;

  const _PermissionRow({Key? key, required this.permission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 2, right: 8, left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: permission.granted ? Colors.green : Colors.grey,
            ),
          ),
          Expanded(
            child: SelectableText(
              permission.name,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
          if (permission.granted)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '已授予',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
            ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: permission.name));
              SmartDialogUtils.showSuccess('已复制权限');
            },
            icon: const Icon(Icons.copy, size: 14),
            tooltip: '复制',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ],
      ),
    );
  }
}
