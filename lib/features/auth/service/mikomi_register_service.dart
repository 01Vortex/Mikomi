import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mikomi/config/api_config.dart';
import 'package:mikomi/core/services/api_service.dart';

class MikomiRegisterService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> sendVerificationCode(String email) async {
    try {
      debugPrint('发送验证码请求: $email');
      final response = await _apiService.dio.post(
        AuthApi.sendCode,
        data: {'email': email},
      );

      debugPrint('验证码响应: ${response.statusCode}');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('验证码请求失败: ${e.type}');
      debugPrint('错误详情: ${e.message}');
      if (e.response != null) {
        debugPrint('响应数据: ${e.response!.data}');
        throw Exception(e.response!.data['error'] ?? '发送验证码失败');
      }
      throw Exception('网络连接失败，请检查网络设置');
    }
  }

  Future<RegisterResponse?> register({
    required String nickname,
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      debugPrint('注册请求: $email');
      final response = await _apiService.dio.post(
        AuthApi.register,
        data: {
          'nickname': nickname,
          'email': email,
          'password': password,
          'code': code,
        },
      );

      debugPrint('注册响应: ${response.statusCode}');
      if (response.statusCode == 201) {
        return RegisterResponse.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('注册请求失败: ${e.type}');
      debugPrint('错误详情: ${e.message}');
      if (e.response != null) {
        debugPrint('响应数据: ${e.response!.data}');
        throw Exception(e.response!.data['error'] ?? '注册失败');
      }
      throw Exception('网络连接失败，请检查网络设置');
    }
  }
}

class RegisterResponse {
  final String token;
  final UserInfo user;

  RegisterResponse({required this.token, required this.user});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      token: json['token'] as String,
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserInfo {
  final int id;
  final String account;
  final String nickname;
  final String email;

  UserInfo({
    required this.id,
    required this.account,
    required this.nickname,
    required this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      account: json['account'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
    );
  }
}
