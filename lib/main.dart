import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/parse/parsing.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  bool supported = false;
  try {
    supported = await PlatformWebViewFeature.static()
        .isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT);
  } catch (_) {
    supported = false;
  }
  ParsingFactory.setDocumentStartScriptSupported(supported);

  runApp(const MyApp());
}
