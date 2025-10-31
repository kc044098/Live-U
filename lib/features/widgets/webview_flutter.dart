import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebDocPage extends StatefulWidget {
  final String title;
  final String url;
  const WebDocPage({super.key, required this.title, required this.url});

  @override
  State<WebDocPage> createState() => _WebDocPageState();
}

class _WebDocPageState extends State<WebDocPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}