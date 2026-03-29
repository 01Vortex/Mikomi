import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum HwDecoder {
  auto,
  mediacodec,
  mediacodecCopy,
  videotoolbox,
  none;

  String get hwdecValue => switch (this) {
        HwDecoder.auto => 'auto-safe',
        HwDecoder.mediacodec => 'mediacodec',
        HwDecoder.mediacodecCopy => 'mediacodec-copy',
        HwDecoder.videotoolbox => 'videotoolbox',
        HwDecoder.none => 'no',
      };

  String get label => switch (this) {
        HwDecoder.auto => '自动',
        HwDecoder.mediacodec => 'MediaCodec',
        HwDecoder.mediacodecCopy => 'MediaCodec (Copy)',
        HwDecoder.videotoolbox => 'VideoToolbox',
        HwDecoder.none => '关闭',
      };

  String get description => switch (this) {
        HwDecoder.auto => '自动选择最佳解码器，兼容性最好',
        HwDecoder.mediacodec => '使用 Android 硬件解码，直接渲染，性能最优',
        HwDecoder.mediacodecCopy => '使用 Android 硬件解码，复制帧，兼容性较好',
        HwDecoder.videotoolbox => '使用 Apple VideoToolbox 硬件解码',
        HwDecoder.none => '纯软件解码，性能较低但兼容性最佳',
      };

  static List<HwDecoder> get platformDecoders {
    if (Platform.isAndroid) {
      return [HwDecoder.auto, HwDecoder.mediacodecCopy, HwDecoder.mediacodec, HwDecoder.none];
    } else if (Platform.isIOS) {
      return [HwDecoder.auto, HwDecoder.videotoolbox, HwDecoder.none];
    }
    return [HwDecoder.auto, HwDecoder.none];
  }

  static HwDecoder fromValue(String value) {
    return HwDecoder.values.firstWhere(
      (e) => e.hwdecValue == value,
      orElse: () => HwDecoder.auto,
    );
  }
}

class HardwareDecodeService {
  static const String _keyEnabled = 'hardware_decoding';
  static const String _keyDecoder = 'hw_decoder';

  Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  Future<HwDecoder> getDecoder() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyDecoder) ?? HwDecoder.auto.hwdecValue;
    return HwDecoder.fromValue(value);
  }

  Future<void> setDecoder(HwDecoder decoder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDecoder, decoder.hwdecValue);
  }
}
