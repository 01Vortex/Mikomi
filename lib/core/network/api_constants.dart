class ApiConstants {
  static const String bangumiApiDomain = 'https://api.bgm.tv';
  static const String bangumiApiNextDomain = 'https://next.bgm.tv';

  static const String bangumiTrends = '/p1/trending/subjects';
  static const String bangumiCalendar = '/p1/calendar';
  static const String bangumiSearch = '/v0/search/subjects';

  static String formatUrl(String url, List<dynamic> params) {
    for (int i = 0; i < params.length; i++) {
      url = url.replaceAll('{$i}', params[i].toString());
    }
    return url;
  }
}
