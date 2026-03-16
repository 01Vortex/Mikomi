import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PilgrimagePage extends StatelessWidget {
  const PilgrimagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('https://www.anitabi.cn/map?c=140.3673,36.1288&z=5'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useHybridComposition: true,
            hardwareAcceleration: true,
            cacheEnabled: true,
            supportZoom: true,
            disableContextMenu: true,
            useShouldInterceptAjaxRequest: false,
            useShouldInterceptFetchRequest: false,
            useOnLoadResource: false,
            useOnDownloadStart: false,
            disableDefaultErrorPage: true,
            preferredContentMode: UserPreferredContentMode.MOBILE,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          ),
        ),
      ),
    );
  }
}
