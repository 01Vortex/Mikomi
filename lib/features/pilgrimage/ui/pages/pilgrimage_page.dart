import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PilgrimagePage extends StatefulWidget {
  const PilgrimagePage({super.key});

  @override
  State<PilgrimagePage> createState() => _PilgrimagePageState();
}

class _PilgrimagePageState extends State<PilgrimagePage> {
  static final URLRequest _initialRequest = URLRequest(
    url: WebUri('https://www.anitabi.cn/map?c=140.3673,36.1288&z=5'),
  );

  static final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    cacheEnabled: true,
    supportZoom: true,
    disableContextMenu: true,
    useOnLoadResource: false,
    useOnDownloadStart: false,
    disableDefaultErrorPage: true,
    preferredContentMode: UserPreferredContentMode.MOBILE,
  );

  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    await _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: _initialRequest,
              initialSettings: _settings,
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (_, _) {
                if (!mounted) return;
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              },
              onLoadStop: (_, _) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
              },
              onReceivedError: (_, _, _) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              },
              onReceivedHttpError: (_, _, _) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              },
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_hasError)
              ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 44),
                      const SizedBox(height: 10),
                      const Text('巡礼地图加载失败'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _retry,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
