class WatchHistory {
  final int bangumiId;
  final String bangumiName;
  final String bangumiNameCn;
  final String coverUrl;
  final int lastWatchEpisode;
  final String lastWatchEpisodeName;
  final DateTime lastWatchTime;
  final String pluginName;
  final Duration progress;
  final Duration duration; // 视频总时长

  WatchHistory({
    required this.bangumiId,
    required this.bangumiName,
    required this.bangumiNameCn,
    required this.coverUrl,
    required this.lastWatchEpisode,
    required this.lastWatchEpisodeName,
    required this.lastWatchTime,
    required this.pluginName,
    required this.progress,
    required this.duration,
  });

  String get displayName =>
      bangumiNameCn.isNotEmpty ? bangumiNameCn : bangumiName;

  String get title => displayName;

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
      'bangumiId': bangumiId,
      'bangumiName': bangumiName,
      'bangumiNameCn': bangumiNameCn,
      'coverUrl': coverUrl,
      'lastWatchEpisode': lastWatchEpisode,
      'lastWatchEpisodeName': lastWatchEpisodeName,
      'lastWatchTime': lastWatchTime.toIso8601String(),
      'pluginName': pluginName,
      'progress': progress.inMilliseconds,
      'duration': duration.inMilliseconds,
    };
  }

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      bangumiId: json['bangumiId'] ?? 0,
      bangumiName: json['bangumiName'] ?? '',
      bangumiNameCn: json['bangumiNameCn'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      lastWatchEpisode: json['lastWatchEpisode'] ?? 0,
      lastWatchEpisodeName: json['lastWatchEpisodeName'] ?? '',
      lastWatchTime: DateTime.parse(
        json['lastWatchTime'] ?? DateTime.now().toIso8601String(),
      ),
      pluginName: json['pluginName'] ?? '',
      progress: Duration(milliseconds: json['progress'] ?? 0),
      duration: Duration(milliseconds: json['duration'] ?? 0),
    );
  }
}
