import 'package:flutter/material.dart';

class Danmaku {
  // 弹幕内容
  final String message;
  // 弹幕时间（秒）
  final double time;
  // 弹幕类型 (1-普通弹幕，4-底部弹幕，5-顶部弹幕)
  final int type;
  // 弹幕颜色
  final Color color;
  // 弹幕来源
  final String source;

  Danmaku({
    required this.message,
    required this.time,
    required this.type,
    required this.color,
    required this.source,
  });

  factory Danmaku.fromJson(Map<String, dynamic> json) {
    String messageValue = json['m'];
    List<String> parts = json['p'].split(',');
    double timeValue = double.parse(parts[0]);
    int typeValue = int.parse(parts[1]);
    int colorInt = int.parse(parts[2]);
    String sourceValue = parts.length > 3 ? parts[3] : 'DanDanPlay';

    // 将整数颜色值转换为Color对象
    Color color = Color(0xFF000000 | colorInt);

    return Danmaku(
      time: timeValue,
      message: messageValue,
      type: typeValue,
      color: color,
      source: sourceValue,
    );
  }

  Map<String, dynamic> toJson() {
    final colorValue = ((color.red) << 16) | ((color.green) << 8) | color.blue;
    return {'m': message, 'p': '$time,$type,$colorValue,$source'};
  }
}
