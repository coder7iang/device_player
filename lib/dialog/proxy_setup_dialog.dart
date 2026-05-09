import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:device_player/services/adb_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _CertEntry {
  final String tool;
  final String url;

  const _CertEntry(this.tool, this.url);
}

class _ProxySetupDialogState extends State<ProxySetupDialog> {
  static const List<_ProxyPreset> _presets = [
    _ProxyPreset('Charles', '8888'),
    _ProxyPreset('Proxyman', '9090'),
    _ProxyPreset('Whistle', '8899'),
    _ProxyPreset('mitmproxy', '8080'),
  ];

  static const List<_CertEntry> _certs = [
    _CertEntry('Charles', 'chls.pro/ssl'),
    _CertEntry('Proxyman', 'proxy.man/ssl'),
    _CertEntry('Whistle', 'rootca.pro'),
    _CertEntry('mitmproxy', 'mitm.it'),
  ];

  late final TextEditingController _ipController;
  late final TextEditingController _portController;

  String _localIp = '';
  String _currentProxy = '';
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
    final proxy = await AdbService.instance.getHttpProxy();
    if (!mounted) return;
    setState(() {
      _localIp = ip;
      _currentProxy = proxy;
      if (_ipController.text.isEmpty && ip != '未知') {
        _ipController.text = ip;
      }
      _busy = false;
    });
  }

  Future<void> _applyProxy() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    if (ip.isEmpty || port.isEmpty) {
      SmartDialogUtils.showError('请填写 IP 和端口');
      return;
    }
    setState(() => _busy = true);
    final ok = await AdbService.instance.setHttpProxy(ip, port);
    if (!mounted) return;
    if (ok) {
      SmartDialogUtils.showSuccess('已设置代理: $ip:$port');
      await _refresh();
    } else {
      setState(() => _busy = false);
      SmartDialogUtils.showError('设置代理失败');
    }
  }

  Future<void> _clearProxy() async {
    setState(() => _busy = true);
    final ok = await AdbService.instance.clearHttpProxy();
    if (!mounted) return;
    if (ok) {
      SmartDialogUtils.showSuccess('已取消代理');
      await _refresh();
    } else {
      setState(() => _busy = false);
      SmartDialogUtils.showError('取消代理失败');
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

  void _copyCertUrl(String url) {
    Clipboard.setData(ClipboardData(text: 'http://$url'));
    SmartDialogUtils.showSuccess('已复制: http://$url');
  }

  @override
  Widget build(BuildContext context) {
    final hasProxy = _currentProxy.isNotEmpty;
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
                  tooltip: '刷新',
                ),
                IconButton(
                  onPressed: () => SmartDialog.dismiss(),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: '关闭',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusBar(hasProxy),
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
            _buildActionRow(hasProxy),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text('证书安装地址（手机浏览器打开后下载、然后到设置 → 安全 → 安装证书）',
                style: TextStyle(
                    color: Colors.grey, fontSize: 12, height: 1.4)),
            const SizedBox(height: 8),
            ..._certs.map(_buildCertRow),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool hasProxy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasProxy ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasProxy ? const Color(0xFF66BB6A) : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasProxy ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: hasProxy ? const Color(0xFF388E3C) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasProxy ? '当前代理: $_currentProxy' : '当前未挂代理',
              style: TextStyle(
                fontSize: 13,
                color:
                    hasProxy ? const Color(0xFF1B5E20) : Colors.grey.shade700,
              ),
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
      ],
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

  Widget _buildActionRow(bool hasProxy) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _applyProxy,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('设置代理'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_busy || !hasProxy) ? null : _clearProxy,
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('取消代理'),
          ),
        ),
      ],
    );
  }

  Widget _buildCertRow(_CertEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              entry.tool,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              'http://${entry.url}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          IconButton(
            onPressed: () => _copyCertUrl(entry.url),
            icon: const Icon(Icons.copy, size: 14),
            tooltip: '复制',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
