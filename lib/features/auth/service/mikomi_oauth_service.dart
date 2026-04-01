import 'package:dio/dio.dart';
import 'package:mikomi/core/network/app_api.dart';
import 'package:mikomi/core/services/api_service.dart';

class MikomiOAuthService {
  final ApiService _apiService = ApiService();

  Future<OAuthLoginResponse?> oauthLogin({
    required String provider,
    required String providerUserId,
    required String accessToken,
    String? providerUsername,
    String? refreshToken,
    int? expiresIn,
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? email,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AuthApi.oauthLogin,
        data: {
          'provider': provider,
          'provider_user_id': providerUserId,
          'access_token': accessToken,
          if (providerUsername != null) 'provider_username': providerUsername,
          if (refreshToken != null) 'refresh_token': refreshToken,
          if (expiresIn != null) 'expires_in': expiresIn,
          if (nickname != null) 'nickname': nickname,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (bio != null) 'bio': bio,
          if (email != null) 'email': email,
        },
      );

      if (response.statusCode == 200) {
        final oauthResponse = OAuthLoginResponse.fromJson(response.data);
        _apiService.setAuthToken(oauthResponse.token);
        return oauthResponse;
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'OAuth登录失败');
      }
      throw Exception('网络连接失败');
    }
  }
}

class OAuthLoginResponse {
  final String token;
  final OAuthUserInfo user;
  final bool isNewUser;
  final String? mikomiAccount;

  OAuthLoginResponse({
    required this.token,
    required this.user,
    required this.isNewUser,
    this.mikomiAccount,
  });

  factory OAuthLoginResponse.fromJson(Map<String, dynamic> json) {
    return OAuthLoginResponse(
      token: json['token'] as String,
      user: OAuthUserInfo.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['is_new_user'] as bool,
      mikomiAccount: json['mikomi_account'] as String?,
    );
  }
}

class OAuthUserInfo {
  final int id;
  final String account;
  final String nickname;
  final String email;

  OAuthUserInfo({
    required this.id,
    required this.account,
    required this.nickname,
    required this.email,
  });

  factory OAuthUserInfo.fromJson(Map<String, dynamic> json) {
    return OAuthUserInfo(
      id: json['id'] as int,
      account: json['account'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
    );
  }
}
