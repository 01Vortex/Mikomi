class ApiConfig {
  // 真机使用电脑局域网IP，Android模拟器使用 10.0.2.2，iOS模拟器和Web使用 localhost
  static const String baseUrl = 'http://192.168.1.2:8080';
  static const String apiVersion = '/api/v1';

  static String get apiBaseUrl => '$baseUrl$apiVersion';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class AuthApi {
  static const String sendCode = '/auth/send-code';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String oauthLogin = '/auth/oauth-login';
  static const String forgotPassword = '/auth/forgot-password';
}

class CommentApi {
  static const String create = '/comments';
  static String getByAnimeId(String animeId) => '/comments/$animeId';
  static String delete(String id) => '/comments/$id';
}

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
