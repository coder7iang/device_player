import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 仅包含 WebView 的通用网页内容组件，可嵌入任意布局中使用
class CommonWebContent extends StatefulWidget {
  const CommonWebContent({
    Key? key,
    required this.url,
  }) : super(key: key);

  /// 要加载的网页链接
  final String url;

  @override
  State<CommonWebContent> createState() => _CommonWebContentState();
}

class _CommonWebContentState extends State<CommonWebContent> {
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
    return WebViewWidget(
      controller: _webViewController,
    );
  }
}

/// 带 AppBar 的整页通用网页展示页，可直接通过 Navigator.push 打开
class CommonWebPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(title),
        centerTitle: false,
        backgroundColor: Colors.white,
      ),
      body: CommonWebContent(url: url),
    );
  }
}

