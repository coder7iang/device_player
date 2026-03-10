import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 通用网页展示页
class CommonWebPage extends StatefulWidget {
  const CommonWebPage({
    Key? key,
    required this.title,
    required this.url,
  }) : super(key: key);

  /// 页面标题
  final String title;

  /// 要加载的网页链接
  final String url;

  @override
  State<CommonWebPage> createState() => _CommonWebPageState();
}

class _CommonWebPageState extends State<CommonWebPage> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(widget.title),
        centerTitle: false,
        backgroundColor: Colors.white,
      ),
      body: WebViewWidget(
        controller: _webViewController,
      ),
    );
  }
}

