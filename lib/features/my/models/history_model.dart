import 'package:mikomi/features/my/models/my_anime_ref_model.dart';

class HistoryModel extends MyAnimeRefModel {
  final int lastWatchEpisode;
  final String lastWatchEpisodeName;
  final DateTime lastWatchTime;
  final String pluginName;
  final Duration progress;
  final Duration duration;
  final String cachedPlayUrl;
  final DateTime? cachedPlayUrlTime;

  HistoryModel({
    required super.bangumiId,
    required super.bangumiName,
    required super.bangumiNameCn,
    required this.lastWatchEpisode,
    required this.lastWatchEpisodeName,
    required this.lastWatchTime,
    required this.pluginName,
    required this.progress,
    required this.duration,
    this.cachedPlayUrl = '',
    this.cachedPlayUrlTime,
  });

  String get episodeDisplay => lastWatchEpisodeName.isNotEmpty
      ? lastWatchEpisodeName
      : '第$lastWatchEpisode话';

  String get episodeTitle => episodeDisplay;

  double get progressPercent {
    if (progress.inSeconds == 0 || duration.inSeconds == 0) return 0;
    final percent = (progress.inSeconds / duration.inSeconds) * 100;
    return percent.clamp(0, 100);
  }

  Map<String, dynamic> toJson() {
    return {
      ...toBaseJson(),
      'lastWatchEpisode': lastWatchEpisode,
      'lastWatchEpisodeName': lastWatchEpisodeName,
      'lastWatchTime': lastWatchTime.toIso8601String(),
      'pluginName': pluginName,
      'progress': progress.inMilliseconds,
      'duration': duration.inMilliseconds,
      'cachedPlayUrl': cachedPlayUrl,
      'cachedPlayUrlTime': cachedPlayUrlTime?.toIso8601String(),
    };
  }

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      bangumiId: json['bangumiId'] ?? 0,
      bangumiName: json['bangumiName'] ?? '',
      bangumiNameCn: json['bangumiNameCn'] ?? '',
      lastWatchEpisode: json['lastWatchEpisode'] ?? 0,
      lastWatchEpisodeName: json['lastWatchEpisodeName'] ?? '',
      lastWatchTime: DateTime.parse(
        json['lastWatchTime'] ?? DateTime.now().toIso8601String(),
      ),
      pluginName: json['pluginName'] ?? '',
      progress: Duration(milliseconds: json['progress'] ?? 0),
      duration: Duration(milliseconds: json['duration'] ?? 0),
      cachedPlayUrl: json['cachedPlayUrl'] ?? '',
      cachedPlayUrlTime: json['cachedPlayUrlTime'] != null
          ? DateTime.tryParse(json['cachedPlayUrlTime'])
          : null,
    );
  }
}
