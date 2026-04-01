import 'package:mikomi/core/models/episode.dart';

class VideoStateManager {
  int currentEpisode = 1;
  List<Episode> episodes = [];
  String videoUrl = '';
  String? currentPluginName;
  bool isDescending = false;
  bool isDanmakuEnabled = false;
  bool isDanmakuInputExpanded = false;
  bool isEpisodesExpanded = true;
  bool showTimeoutHint = false;
  bool hasParseError = false;
  bool isLoadingEpisodes = false;
  bool isUsingCachedPlayUrl = false;
  String lastResolvedVideoUrl = '';
  bool isReassembling = false;
  bool shouldParseAfterEpisodesLoaded = false;

  int get totalEpisodes => episodes.length;

  String? get currentEpisodeTitle {
    try {
      return episodes.firstWhere((ep) => ep.number == currentEpisode).title;
    } catch (_) {
      return null;
    }
  }

  bool get hasNextEpisode => currentEpisode < totalEpisodes;
  bool get hasPreviousEpisode => currentEpisode > 1;

  List<Episode> get sortedEpisodes =>
      isDescending ? episodes.reversed.toList() : episodes;

  void reset() {
    currentEpisode = 1;
    episodes = [];
    videoUrl = '';
    currentPluginName = null;
    isDescending = false;
    isDanmakuEnabled = false;
    isDanmakuInputExpanded = false;
    isEpisodesExpanded = true;
    showTimeoutHint = false;
    hasParseError = false;
    isLoadingEpisodes = false;
    isUsingCachedPlayUrl = false;
    lastResolvedVideoUrl = '';
    isReassembling = false;
    shouldParseAfterEpisodesLoaded = false;
  }
}
