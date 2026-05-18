import 'package:device_player/services/adb_service.dart';
import 'package:flutter/material.dart';

/// 无线连接对话框 - 支持 ADB 无线配对和连接
class WirelessConnectDialog extends StatefulWidget {
  const WirelessConnectDialog({Key? key}) : super(key: key);

  @override
  State<WirelessConnectDialog> createState() => _WirelessConnectDialogState();
}

class _WirelessConnectDialogState extends State<WirelessConnectDialog> {
  final _ipController = TextEditingController();
  final _connectPortController = TextEditingController();
  final _pairPortController = TextEditingController();
  final _pairCodeController = TextEditingController();

  String _localIp = '获取中...';
  String _statusMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalIp();
    // 任一配对字段变化都触发按钮文案刷新
    _pairPortController.addListener(() => setState(() {}));
    _pairCodeController.addListener(() => setState(() {}));
  }

  Future<void> _loadLocalIp() async {
    var ip = await AdbService.getLocalIp();
    if (mounted) {
      setState(() => _localIp = ip);
    }
  }

  bool get _needPair =>
      _pairPortController.text.trim().isNotEmpty ||
      _pairCodeController.text.trim().isNotEmpty;

  static const _portRange = '1-65535';

  bool _isValidPort(String s) {
    final p = int.tryParse(s);
    return p != null && p >= 1 && p <= 65535;
  }

  Future<void> _doAction() async {
    var ip = _ipController.text.trim();
    var connectPort = _connectPortController.text.trim();
    var pairPort = _pairPortController.text.trim();
    var pairCode = _pairCodeController.text.trim();

    if (ip.isEmpty || connectPort.isEmpty) {
      setState(() => _statusMessage = '请填写 IP 地址和连接端口');
      return;
    }
    if (!_isValidPort(connectPort)) {
      setState(() => _statusMessage = '连接端口需为 $_portRange 之间的整数');
      return;
    }

    // 部分填写配对信息按未填处理
    final doPair = pairPort.isNotEmpty && pairCode.isNotEmpty;
    if (_needPair && !doPair) {
      setState(() => _statusMessage = '请同时填写配对端口和配对码，或都留空');
      return;
    }
    if (doPair && !_isValidPort(pairPort)) {
      setState(() => _statusMessage = '配对端口需为 $_portRange 之间的整数');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = doPair ? '正在配对...' : '正在连接...';
    });

    if (doPair) {
      var pairResult =
          await AdbService.instance.pairDevice(ip, pairPort, pairCode);
      if (!mounted) return;
      if (pairResult != '配对成功') {
        setState(() {
          _isLoading = false;
          _statusMessage = pairResult;
        });
        return;
      }
      setState(() => _statusMessage = '配对成功，正在连接...');
    }

    var connectResult =
        await AdbService.instance.connectDevice(ip, connectPort);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _statusMessage = connectResult;
    });

    if (connectResult == '连接成功') {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _connectPortController.dispose();
    _pairPortController.dispose();
    _pairCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needPair = _needPair;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 480,
          maxWidth: 520,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '无线连接',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '本机IP: $_localIp',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '操作步骤:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. 手机打开 设置 > 开发者选项 > 无线调试\n'
                      '2. 主页顶部「IP地址和端口」即为 IP 和"连接端口"\n'
                      '3. 首次使用：点「使用配对码配对设备」获取"配对端口"和"配对码"，填到下方\n'
                      '4. 已配对过的设备：配对端口/配对码留空，直接连接',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP 地址',
                        hintText: '如 192.168.1.100',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _connectPortController,
                      decoration: const InputDecoration(
                        labelText: '连接端口',
                        hintText: '如 40635',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '首次配对（已配对过可留空）',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _pairCodeController,
                      decoration: const InputDecoration(
                        labelText: '配对码',
                        hintText: '6位配对码',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _pairPortController,
                      decoration: const InputDecoration(
                        labelText: '配对端口',
                        hintText: '如 37755',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _doAction,
                  icon: Icon(
                    needPair ? Icons.phonelink_ring : Icons.wifi,
                    size: 18,
                  ),
                  label: Text(needPair ? '配对并连接' : '连接'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('成功')
                        ? Colors.green[50]
                        : _statusMessage.contains('中...')
                            ? Colors.blue[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (!_isLoading)
                        Icon(
                          _statusMessage.contains('成功')
                              ? Icons.check_circle
                              : Icons.info,
                          size: 16,
                          color: _statusMessage.contains('成功')
                              ? Colors.green
                              : Colors.red,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: _statusMessage.contains('成功')
                                ? Colors.green[700]
                                : _statusMessage.contains('中...')
                                    ? Colors.blue[700]
                                    : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
