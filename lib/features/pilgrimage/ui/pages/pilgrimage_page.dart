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
    javaScriptCanOpenWindowsAutomatically: false,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
    supportZoom: true,
    builtInZoomControls: false,
    displayZoomControls: false,
    disableContextMenu: true,
    useOnLoadResource: false,
    useOnDownloadStart: false,
    disableDefaultErrorPage: false,
    transparentBackground: false,
    mediaPlaybackRequiresUserGesture: true,
    allowsInlineMediaPlayback: true,
    allowsBackForwardNavigationGestures: false,
    preferredContentMode: UserPreferredContentMode.MOBILE,
  );

  bool _showWebView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showWebView = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _showWebView
            ? InAppWebView(
                initialUrlRequest: _initialRequest,
                initialSettings: _settings,
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
