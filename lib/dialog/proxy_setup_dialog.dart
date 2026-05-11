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

class _AutoRevertOption {
  final String label;
  final int minutes;

  const _AutoRevertOption(this.label, this.minutes);
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
  String _currentProxy = '';
  bool _busy = true;
  int _autoRevertMinutes = 60; // 默认 60 分钟自动取消，防止拔线断网

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
    // 先清掉之前可能残留的定时清代理任务，避免多个定时器同时跑
    await AdbService.instance.cancelScheduledProxyClear();
    final ok = await AdbService.instance.setHttpProxy(ip, port);
    if (!mounted) return;
    if (ok) {
      if (_autoRevertMinutes > 0) {
        await AdbService.instance
            .scheduleProxyClear(_autoRevertMinutes * 60);
        SmartDialogUtils.showSuccess(
            '已设置代理: $ip:$port\n$_autoRevertMinutes 分钟后自动取消');
      } else {
        SmartDialogUtils.showSuccess('已设置代理: $ip:$port');
      }
      // 乐观更新 UI：Settings Provider 写完到读会有几十~几百毫秒同步延迟，
      // 直接用刚写入的值更新状态，避免立刻 read 拿到旧值
      if (!mounted) return;
      debugPrint('[ProxyDialog] applyProxy ok, setting _currentProxy=$ip:$port');
      setState(() {
        _currentProxy = '$ip:$port';
        _busy = false;
      });
      debugPrint('[ProxyDialog] after setState, _currentProxy=$_currentProxy');
    } else {
      setState(() => _busy = false);
      SmartDialogUtils.showError('设置代理失败');
    }
  }

  Future<void> _clearProxy() async {
    setState(() => _busy = true);
    await AdbService.instance.cancelScheduledProxyClear();
    final ok = await AdbService.instance.clearHttpProxy();
    if (!mounted) return;
    if (ok) {
      SmartDialogUtils.showSuccess('已取消代理');
      setState(() {
        _currentProxy = '';
        _busy = false;
      });
    } else {
      setState(() => _busy = false);
      SmartDialogUtils.showError('取消代理失败');
    }
  }

  Future<void> _openWifiSettings() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    // 提前把 IP:端口复制到桌面剪贴板，方便用户粘贴前对照
    if (ip.isNotEmpty && port.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: '$ip:$port'));
    }
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

  @override
  Widget build(BuildContext context) {
    final hasProxy = _currentProxy.isNotEmpty;
    debugPrint('[ProxyDialog] build, _currentProxy=$_currentProxy, hasProxy=$hasProxy, _busy=$_busy');
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
            const SizedBox(height: 12),
            _buildAutoRevertRow(),
            const SizedBox(height: 8),
            _buildWarningBanner(),
            const SizedBox(height: 16),
            _buildActionRow(hasProxy),
            const SizedBox(height: 8),
            _buildWifiShortcut(),
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

  Widget _buildAutoRevertRow() {
    const options = <_AutoRevertOption>[
      _AutoRevertOption('不自动', 0),
      _AutoRevertOption('30 分钟', 30),
      _AutoRevertOption('60 分钟', 60),
      _AutoRevertOption('120 分钟', 120),
    ];
    return Row(
      children: [
        const SizedBox(
          width: 56,
          child: Text('自动取消', style: TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final selected = _autoRevertMinutes == o.minutes;
              return ChoiceChip(
                label: Text(o.label, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: _busy
                    ? null
                    : (_) => setState(() => _autoRevertMinutes = o.minutes),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFF57C00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '全局代理是设备级且持久化，重启都不会清。建议保留"自动取消"，避免拔线后手机断网。',
              style: TextStyle(fontSize: 12, color: Color(0xFF6D4C00), height: 1.4),
            ),
          ),
        ],
      ),
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
              '想用 WiFi 专属代理？打开手机 WiFi 设置后手动填入上面的 IP / 端口',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _openWifiSettings,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('打开 WiFi 设置', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
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

}
