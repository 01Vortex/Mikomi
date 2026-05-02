/// 反反爬虫验证类型
class CaptchaType {
  static const int imageCaptcha = 1;
  static const int autoClickButton = 2;
}

/// 反反爬虫配置
///
/// 注意：验证码/确认按钮会由解析器自动识别并点击。
/// [captchaButton] 只是插件作者可选提供的 XPath 兜底 hint，
/// 不应该作为需要用户手动点击或手动配置的必填项。
class AntiCrawlerConfig {
  final bool enabled;
  final int captchaType;
  final String captchaImage;
  final String captchaInput;
  final String captchaButton;

  AntiCrawlerConfig({
    required this.enabled,
    required this.captchaType,
    required this.captchaImage,
    required this.captchaInput,
    required this.captchaButton,
  });

  factory AntiCrawlerConfig.fromJson(Map<String, dynamic> json) {
    return AntiCrawlerConfig(
      enabled: json['enabled'] ?? false,
      captchaType: json['captchaType'] ?? CaptchaType.imageCaptcha,
      captchaImage: json['captchaImage'] ?? '',
      captchaInput: json['captchaInput'] ?? '',
      captchaButton: json['captchaButton'] ?? '',
    );
  }

  factory AntiCrawlerConfig.empty() {
    return AntiCrawlerConfig(
      enabled: false,
      captchaType: CaptchaType.imageCaptcha,
      captchaImage: '',
      captchaInput: '',
      captchaButton: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'captchaType': captchaType,
      'captchaImage': captchaImage,
      'captchaInput': captchaInput,
      'captchaButton': captchaButton,
    };
  }
}

class VideoPlugin {
  final String id;
  final String api;
  final String type;
  final String name;
  final String version;
  final bool multiSources;
  final bool useWebview;
  final bool useNativePlayer;
  final bool usePost;
  final bool useLegacyParser;
  final bool adBlocker;
  final String userAgent;
  final String baseURL;
  final String searchURL;
  final String searchList;
  final String searchName;
  final String searchResult;
  final String chapterRoads;
  final String chapterResult;
  final String referer;
  final AntiCrawlerConfig antiCrawlerConfig;

  VideoPlugin({
    String? id,
    required this.api,
    required this.type,
    required this.name,
    required this.version,
    required this.multiSources,
    required this.useWebview,
    required this.useNativePlayer,
    required this.usePost,
    required this.useLegacyParser,
    required this.adBlocker,
    required this.userAgent,
    required this.baseURL,
    required this.searchURL,
    required this.searchList,
    required this.searchName,
    required this.searchResult,
    required this.chapterRoads,
    required this.chapterResult,
    required this.referer,
    AntiCrawlerConfig? antiCrawlerConfig,
  }) : id = id ?? _generateId(),
       antiCrawlerConfig = antiCrawlerConfig ?? AntiCrawlerConfig.empty();

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  factory VideoPlugin.fromJson(Map<String, dynamic> json) {
    return VideoPlugin(
      id: json['id'] as String?,
      api: json['api'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      multiSources: json['muliSources'] ?? json['multiSources'] ?? false,
      useWebview: json['useWebview'] ?? false,
      useNativePlayer: json['useNativePlayer'] ?? true,
      usePost: json['usePost'] ?? false,
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
      referer: json['referer'] ?? '',
      antiCrawlerConfig: json['antiCrawlerConfig'] != null
          ? AntiCrawlerConfig.fromJson(
              Map<String, dynamic>.from(json['antiCrawlerConfig']),
            )
          : AntiCrawlerConfig.empty(),
    );
  }

  factory VideoPlugin.fromTemplate() {
    return VideoPlugin(
      api: '1',
      type: 'anime',
      name: '',
      version: '',
      multiSources: true,
      useWebview: true,
      useNativePlayer: true,
      usePost: false,
      useLegacyParser: false,
      adBlocker: false,
      userAgent: '',
      baseURL: '',
      searchURL: '',
      searchList: '',
      searchName: '',
      searchResult: '',
      chapterRoads: '',
      chapterResult: '',
      referer: '',
      antiCrawlerConfig: AntiCrawlerConfig.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'api': api,
      'type': type,
      'name': name,
      'version': version,
      'muliSources': multiSources,
      'useWebview': useWebview,
      'useNativePlayer': useNativePlayer,
      'usePost': usePost,
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
      'referer': referer,
      'antiCrawlerConfig': antiCrawlerConfig.toJson(),
    };
  }

  VideoPlugin copyWith({
    String? id,
    String? api,
    String? type,
    String? name,
    String? version,
    bool? multiSources,
    bool? useWebview,
    bool? useNativePlayer,
    bool? usePost,
    bool? useLegacyParser,
    bool? adBlocker,
    String? userAgent,
    String? baseURL,
    String? searchURL,
    String? searchList,
    String? searchName,
    String? searchResult,
    String? chapterRoads,
    String? chapterResult,
    String? referer,
    AntiCrawlerConfig? antiCrawlerConfig,
  }) {
    return VideoPlugin(
      id: id ?? this.id,
      api: api ?? this.api,
      type: type ?? this.type,
      name: name ?? this.name,
      version: version ?? this.version,
      multiSources: multiSources ?? this.multiSources,
      useWebview: useWebview ?? this.useWebview,
      useNativePlayer: useNativePlayer ?? this.useNativePlayer,
      usePost: usePost ?? this.usePost,
      useLegacyParser: useLegacyParser ?? this.useLegacyParser,
      adBlocker: adBlocker ?? this.adBlocker,
      userAgent: userAgent ?? this.userAgent,
      baseURL: baseURL ?? this.baseURL,
      searchURL: searchURL ?? this.searchURL,
      searchList: searchList ?? this.searchList,
      searchName: searchName ?? this.searchName,
      searchResult: searchResult ?? this.searchResult,
      chapterRoads: chapterRoads ?? this.chapterRoads,
      chapterResult: chapterResult ?? this.chapterResult,
      referer: referer ?? this.referer,
      antiCrawlerConfig: antiCrawlerConfig ?? this.antiCrawlerConfig,
    );
  }
}
