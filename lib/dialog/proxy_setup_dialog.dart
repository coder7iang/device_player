import 'package:adb_player/dialog/smart_dialog_utils.dart';
import 'package:adb_player/services/adb_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class ProxySetupDialog extends StatefulWidget {
  const ProxySetupDialog({Key? key}) : super(key: key);

  @override
  State<ProxySetupDialog> createState() => _ProxySetupDialogState();
}

class _ProxyPreset {
  final String label;
  final String port;

  const _ProxyPreset(this.label, this.port);
}

class _ProxySetupDialogState extends State<ProxySetupDialog> {
  static const List<_ProxyPreset> _presets = [
    _ProxyPreset('Charles', '8888'),
    _ProxyPreset('Proxyman', '9090'),
    _ProxyPreset('Whistle', '8899'),
    _ProxyPreset('mitmproxy', '8080'),
  ];

  late final TextEditingController _ipController;
  late final TextEditingController _portController;

  String _localIp = '';
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _portController = TextEditingController(text: '8888');
    _refresh();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    final ip = await AdbService.getLocalIp();
    if (!mounted) return;
    setState(() {
      _localIp = ip;
      if (_ipController.text.isEmpty && ip != '未知') {
        _ipController.text = ip;
      }
      _busy = false;
    });
  }

  Future<void> _openWifiSettings() async {
    final ok = await AdbService.instance.openWifiSettings();
    if (!mounted) return;
    if (ok) {
      SmartDialogUtils.showSuccess('已打开手机 WiFi 设置\n长按 SSID → 修改网络 → 高级 → 代理 → 手动');
    } else {
      SmartDialogUtils.showError('打开 WiFi 设置失败');
    }
  }

  void _useLocalIp() {
    if (_localIp.isNotEmpty && _localIp != '未知') {
      _ipController.text = _localIp;
    }
  }

  void _applyPreset(_ProxyPreset preset) {
    _portController.text = preset.port;
  }

  Future<void> _inputToPhone(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      SmartDialogUtils.showError('内容为空');
      return;
    }
    final ok = await AdbService.instance.inputText(trimmed);
    if (!mounted) return;
    if (ok) {
      SmartDialogUtils.showSuccess('已发送');
    } else {
      SmartDialogUtils.showError('发送失败，请确认手机焦点在输入框');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '代理调试',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: '刷新本机 IP',
                ),
                IconButton(
                  onPressed: () => SmartDialog.dismiss(),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: '关闭',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildIntroBanner(),
            const SizedBox(height: 16),
            const Text('代理服务器',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildIpRow(),
            const SizedBox(height: 8),
            _buildPortRow(),
            const SizedBox(height: 12),
            _buildPresetRow(),
            const SizedBox(height: 16),
            _buildWifiShortcut(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '填好 IP 和端口 → 点"打开 WiFi 设置"跳到手机 → 长按 SSID 改代理 → 在 IP/端口输入框聚焦后，点右侧"输入"按钮把值发到手机',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpRow() {
    return Row(
      children: [
        const SizedBox(
          width: 56,
          child: Text('IP', style: TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              isDense: true,
              hintText: '代理服务器 IP',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _useLocalIp,
          child: Text(
            _localIp.isEmpty || _localIp == '未知'
                ? '本机 IP'
                : '本机 $_localIp',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 4),
        _buildInputToPhoneButton(_ipController, '输入到手机 IP 字段'),
      ],
    );
  }

  Widget _buildPortRow() {
    return Row(
      children: [
        const SizedBox(
          width: 56,
          child: Text('端口', style: TextStyle(fontSize: 13)),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              hintText: '8888',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _buildInputToPhoneButton(_portController, '输入到手机端口字段'),
      ],
    );
  }

  Widget _buildInputToPhoneButton(
      TextEditingController controller, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : () => _inputToPhone(controller.text),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 36),
        ),
        icon: const Icon(Icons.keyboard_outlined, size: 14),
        label: const Text('输入', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildPresetRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets.map((p) {
        return ActionChip(
          label: Text('${p.label} ${p.port}',
              style: const TextStyle(fontSize: 12)),
          onPressed: _busy ? null : () => _applyPreset(p),
        );
      }).toList(),
    );
  }

  Widget _buildWifiShortcut() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '一键打开手机 WiFi 设置',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _busy ? null : _openWifiSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
            ),
            icon: const Icon(Icons.launch, size: 14),
            label:
                const Text('打开 WiFi 设置', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
