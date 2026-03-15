class VideoPlugin {
  final String api;
  final String type;
  final String name;
  final String version;
  final bool multiSources;
  final bool useWebview;
  final bool useNativePlayer;
  final bool useLegacyParser;
  final String userAgent;
  final bool adBlocker;
  final String baseURL;
  final String searchURL;
  final String searchList;
  final String searchName;
  final String searchResult;
  final String chapterRoads;
  final String chapterResult;

  VideoPlugin({
    required this.api,
    required this.type,
    required this.name,
    required this.version,
    required this.multiSources,
    required this.useWebview,
    required this.useNativePlayer,
    required this.useLegacyParser,
    required this.userAgent,
    this.adBlocker = false,
    required this.baseURL,
    required this.searchURL,
    required this.searchList,
    required this.searchName,
    required this.searchResult,
    required this.chapterRoads,
    required this.chapterResult,
  });

  factory VideoPlugin.fromJson(Map<String, dynamic> json) {
    return VideoPlugin(
      api: json['api'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      multiSources: json['muliSources'] ?? json['multiSources'] ?? false,
      useWebview: json['useWebview'] ?? false,
      useNativePlayer: json['useNativePlayer'] ?? false,
      useLegacyParser: json['useLegacyParser'] ?? false,
      userAgent: json['userAgent'] ?? '',
      adBlocker: json['adBlocker'] ?? false,
      baseURL: json['baseURL'] as String,
      searchURL: json['searchURL'] as String,
      searchList: json['searchList'] as String,
      searchName: json['searchName'] as String,
      searchResult: json['searchResult'] as String,
      chapterRoads: json['chapterRoads'] as String,
      chapterResult: json['chapterResult'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'api': api,
      'type': type,
      'name': name,
      'version': version,
      'muliSources': multiSources,
      'useWebview': useWebview,
      'useNativePlayer': useNativePlayer,
      'useLegacyParser': useLegacyParser,
      'userAgent': userAgent,
      'adBlocker': adBlocker,
      'baseURL': baseURL,
      'searchURL': searchURL,
      'searchList': searchList,
      'searchName': searchName,
      'searchResult': searchResult,
      'chapterRoads': chapterRoads,
      'chapterResult': chapterResult,
    };
  }
}
