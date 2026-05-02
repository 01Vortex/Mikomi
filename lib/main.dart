import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mikomi/features/video/parse/parsing.dart';
import 'app.dart';

Future<void> _enableHighRefreshRate() async {
  if (!Platform.isAndroid) return;
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await _enableHighRefreshRate();

  bool supported = false;
  try {
    supported = await PlatformWebViewFeature.static().isFeatureSupported(
      WebViewFeature.DOCUMENT_START_SCRIPT,
    );
  } catch (_) {
    supported = false;
  }
  ParsingFactory.setDocumentStartScriptSupported(supported);

  runApp(const MyApp());
}
