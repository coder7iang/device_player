import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:device_player/entity/app_signature_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class SignatureInfoDialog extends StatelessWidget {
  final AppSignatureInfo info;
  final String packageName;

  const SignatureInfoDialog({
    Key? key,
    required this.info,
    required this.packageName,
  }) : super(key: key);

  List<_SignatureField> _buildFields() {
    return [
      _SignatureField('MD5', info.md5),
      _SignatureField('SHA1', info.sha1),
      _SignatureField('SHA256', info.sha256),
      _SignatureField('主题', info.subject),
      _SignatureField('颁发者', info.issuer),
      _SignatureField('序列号', info.serialNumber),
      _SignatureField('生效时间', info.validFrom),
      _SignatureField('过期时间', info.validTo),
      _SignatureField('签名算法', info.algorithm),
    ].where((e) => e.value.isNotEmpty).toList();
  }

  String _buildAllText(List<_SignatureField> fields) {
    final buf = StringBuffer();
    buf.writeln('包名: $packageName');
    for (final f in fields) {
      buf.writeln('${f.label}: ${f.value}');
    }
    return buf.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final fields = _buildFields();
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
                    '应用签名信息',
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
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: fields.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return _SignatureRow(field: field);
                },
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

class _SignatureField {
  final String label;
  final String value;

  _SignatureField(this.label, this.value);
}

class _SignatureRow extends StatelessWidget {
  final _SignatureField field;

  const _SignatureRow({Key? key, required this.field}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
