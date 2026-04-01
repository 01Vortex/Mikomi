import 'package:dio/dio.dart';
import 'package:mikomi/core/network/app_api.dart';
import 'package:mikomi/core/services/api_service.dart';

class MikomiLoginService {
  final ApiService _apiService = ApiService();

  Future<LoginResponse?> login({
    required String account,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AuthApi.login,
        data: {'account': account, 'password': password},
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(response.data);
        _apiService.setAuthToken(loginResponse.token);
        return loginResponse;
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? '登录失败');
      }
      throw Exception('网络连接失败');
    }
  }

  Future<void> logout() async {
    _apiService.clearAuthToken();
  }
}

class LoginResponse {
  final String token;
  final LoginUserInfo user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: LoginUserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class LoginUserInfo {
  final int id;
  final String account;
  final String nickname;
  final String email;

  LoginUserInfo({
    required this.id,
    required this.account,
    required this.nickname,
    required this.email,
  });

  factory LoginUserInfo.fromJson(Map<String, dynamic> json) {
    return LoginUserInfo(
      id: json['id'] as int,
      account: json['account'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
    );
  }
}
