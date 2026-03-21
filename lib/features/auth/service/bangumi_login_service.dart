import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class BangumiLoginService {
  static const String _baseUrl = 'https://bgm.tv';
  static const String _authorizeUrl = '$_baseUrl/oauth/authorize';
  static const String _tokenUrl = '$_baseUrl/oauth/access_token';
  static const String _tokenStatusUrl = '$_baseUrl/oauth/token_status';

  // TODO: 需要在Bangumi后台注册应用获取
  static const String _clientId = 'bgm579169becf1e6c68c';
  static const String _clientSecret = '4b4a7d4776bae2325c9465491b317992';
  // 使用自定义scheme作为回调地址，格式: mikomi://auth/bangumi
  static const String _redirectUri = 'mikomi://auth/bangumi';

  /// 启动OAuth授权流程
  /// 引导用户访问Bangumi授权页
  Future<bool> startAuthorization({String? state}) async {
    final authUrl = Uri.parse(_authorizeUrl).replace(
      queryParameters: {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        if (state != null) 'state': state,
      },
    );

    try {
      return await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('启动授权失败: $e');
      return false;
    }
  }

  /// 使用授权码换取Access Token
  /// [code] 从回调URL中获取的授权码（有效期60秒）
  /// [state] 可选的随机参数，用于防止CSRF攻击
  Future<BangumiAuthToken?> exchangeToken(String code, {String? state}) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'redirect_uri': _redirectUri,
          if (state != null) 'state': state,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BangumiAuthToken.fromJson(data);
      } else {
        debugPrint('换取Token失败: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('换取Token异常: $e');
      return null;
    }
  }

  /// 刷新Access Token
  /// [refreshToken] 之前获取的refresh token
  Future<BangumiAuthToken?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BangumiAuthToken.fromJson(data);
      } else {
        debugPrint('刷新Token失败: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('刷新Token异常: $e');
      return null;
    }
  }

  /// 查询当前Access Token的状态
  /// [accessToken] 要查询的access token
  Future<BangumiTokenStatus?> getTokenStatus(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenStatusUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'access_token': accessToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BangumiTokenStatus.fromJson(data);
      } else {
        debugPrint('查询Token状态失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('查询Token状态异常: $e');
      return null;
    }
  }

  /// 使用Access Token调用API
  /// [accessToken] 访问令牌
  /// [endpoint] API端点
  Future<http.Response?> callApi(String accessToken, String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      return response;
    } catch (e) {
      debugPrint('调用API异常: $e');
      return null;
    }
  }

  /// 获取当前用户信息
  /// [accessToken] 访问令牌
  Future<BangumiUser?> getCurrentUser(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.bgm.tv/v0/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BangumiUser.fromJson(data);
      } else {
        debugPrint('获取用户信息失败: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('获取用户信息异常: $e');
      return null;
    }
  }
}

/// Bangumi授权令牌
class BangumiAuthToken {
  final String accessToken;
  final int expiresIn;
  final String tokenType;
  final String? scope;
  final String refreshToken;
  final int userId;

  BangumiAuthToken({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
    this.scope,
    required this.refreshToken,
    required this.userId,
  });

  factory BangumiAuthToken.fromJson(Map<String, dynamic> json) {
    return BangumiAuthToken(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String,
      scope: json['scope'] as String?,
      refreshToken: json['refresh_token'] as String,
      userId: json['user_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
      'scope': scope,
      'refresh_token': refreshToken,
      'user_id': userId,
    };
  }
}

/// Bangumi Token状态
class BangumiTokenStatus {
  final String accessToken;
  final String clientId;
  final int expires;
  final String? scope;
  final int userId;

  BangumiTokenStatus({
    required this.accessToken,
    required this.clientId,
    required this.expires,
    this.scope,
    required this.userId,
  });

  factory BangumiTokenStatus.fromJson(Map<String, dynamic> json) {
    return BangumiTokenStatus(
      accessToken: json['access_token'] as String,
      clientId: json['client_id'] as String,
      expires: json['expires'] as int,
      scope: json['scope'] as String?,
      userId: json['user_id'] as int,
    );
  }

  /// Token是否已过期
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expires;
  }
}

/// Bangumi用户信息
class BangumiUser {
  final int id;
  final String username;
  final String nickname;
  final Map<String, String> avatar;
  final String? sign;
  final int? userGroup;

  BangumiUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    this.sign,
    this.userGroup,
  });

  factory BangumiUser.fromJson(Map<String, dynamic> json) {
    return BangumiUser(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      avatar: Map<String, String>.from(json['avatar'] as Map),
      sign: json['sign'] as String?,
      userGroup: json['user_group'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'sign': sign,
      'user_group': userGroup,
    };
  }

  /// 获取头像URL（优先使用large，其次medium，最后small）
  String get avatarUrl {
    return avatar['large'] ?? avatar['medium'] ?? avatar['small'] ?? '';
  }
}
