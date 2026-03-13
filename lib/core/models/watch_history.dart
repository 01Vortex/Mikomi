class WatchHistory {
  final int bangumiId;
  final String title;
  final String coverUrl;
  final int episodeIndex;
  final String episodeTitle;
  final int progress;
  final int duration;
  final DateTime lastWatchTime;

  WatchHistory({
    required this.bangumiId,
    required this.title,
    required this.coverUrl,
    required this.episodeIndex,
    required this.episodeTitle,
    required this.progress,
    required this.duration,
    required this.lastWatchTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'bangumiId': bangumiId,
      'title': title,
      'coverUrl': coverUrl,
      'episodeIndex': episodeIndex,
      'episodeTitle': episodeTitle,
      'progress': progress,
      'duration': duration,
      'lastWatchTime': lastWatchTime.toIso8601String(),
    };
  }

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      bangumiId: json['bangumiId'] ?? 0,
      title: json['title'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      episodeIndex: json['episodeIndex'] ?? 0,
      episodeTitle: json['episodeTitle'] ?? '',
      progress: json['progress'] ?? 0,
      duration: json['duration'] ?? 0,
      lastWatchTime: DateTime.parse(json['lastWatchTime']),
    );
  }

  int get progressPercent {
    if (duration == 0) return 0;
    return ((progress / duration) * 100).round();
  }

  String get progressText {
    final minutes = (progress / 60).floor();
    final seconds = progress % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
