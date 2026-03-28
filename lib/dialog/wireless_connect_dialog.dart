import 'package:device_player/services/adb_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 无线连接对话框 - 支持 ADB 无线配对和连接
class WirelessConnectDialog extends StatefulWidget {
  const WirelessConnectDialog({Key? key}) : super(key: key);

  @override
  State<WirelessConnectDialog> createState() => _WirelessConnectDialogState();
}

class _WirelessConnectDialogState extends State<WirelessConnectDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 配对模式
  final _pairIpController = TextEditingController();
  final _pairPortController = TextEditingController();
  final _pairCodeController = TextEditingController();

  // 连接模式
  final _connectIpController = TextEditingController();
  final _connectPortController = TextEditingController();

  String _localIp = '获取中...';
  String _statusMessage = '';
  bool _isLoading = false;
  bool _isPairSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocalIp();
  }

  Future<void> _loadLocalIp() async {
    var ip = await AdbService.getLocalIp();
    if (mounted) {
      setState(() => _localIp = ip);
    }
  }

  Future<void> _doPair() async {
    var ip = _pairIpController.text.trim();
    var port = _pairPortController.text.trim();
    var code = _pairCodeController.text.trim();

    if (ip.isEmpty || port.isEmpty || code.isEmpty) {
      setState(() => _statusMessage = '请填写完整的配对信息');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在配对...';
    });

    var result = await AdbService.instance.pairDevice(ip, port, code);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = result;
        _isPairSuccess = result == '配对成功';
        if (_isPairSuccess) {
          // 配对成功后自动填充连接 IP
          _connectIpController.text = ip;
        }
      });
    }
  }

  Future<void> _doConnect() async {
    var ip = _connectIpController.text.trim();
    var port = _connectPortController.text.trim();

    if (ip.isEmpty || port.isEmpty) {
      setState(() => _statusMessage = '请填写IP地址和端口');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在连接...';
    });

    var result = await AdbService.instance.connectDevice(ip, port);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = result;
      });

      if (result == '连接成功') {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pairIpController.dispose();
    _pairPortController.dispose();
    _pairCodeController.dispose();
    _connectIpController.dispose();
    _connectPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 480,
          maxWidth: 520,
          minHeight: 500,
          maxHeight: 620,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '无线连接',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '本机IP: $_localIp',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: '配对新设备'),
                  Tab(text: '直接连接'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPairTab(),
                    _buildConnectTab(),
                  ],
                ),
              ),
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPairTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 使用说明
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
                  '2. 点击 "使用配对码配对设备"\n'
                  '3. 将手机上显示的 IP、端口和配对码填入下方',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // IP 和端口输入
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _pairIpController,
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
          const SizedBox(height: 12),
          TextField(
            controller: _pairCodeController,
            decoration: const InputDecoration(
              labelText: '配对码',
              hintText: '手机上显示的6位配对码',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _doPair,
              icon: const Icon(Icons.phonelink_ring, size: 18),
              label: const Text('配对'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_isPairSuccess) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '配对成功！请切换到"直接连接"标签页，输入无线调试端口进行连接',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '已配对的设备可以直接连接。\n端口号在手机 "无线调试" 页面顶部的 "IP地址和端口" 中查看。',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _connectIpController,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _doConnect,
              icon: const Icon(Icons.wifi, size: 18),
              label: const Text('连接'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 二维码区域 - 显示本机 IP
          Center(
            child: Column(
              children: [
                Text(
                  '本机 IP 二维码',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '可用手机扫码快速获取本机 IP',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                if (_localIp != '获取中...' && _localIp != '未知')
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: QrImageView(
                      data: _localIp,
                      version: QrVersions.auto,
                      size: 120,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
