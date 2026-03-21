import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikomi/core/services/api_service.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  int? _userId;
  String? _accessToken;
  MikomiUser? _mikomiUserInfo;

  bool get isLoggedIn => _isLoggedIn;
  int? get userId => _userId;
  String? get accessToken => _accessToken;
  MikomiUser? get mikomiUserInfo => _mikomiUserInfo;

  String? get nickname => _mikomiUserInfo?.nickname;
  String? get email => _mikomiUserInfo?.email;

  // 初始化，从本地存储加载登录状态
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _userId = prefs.getInt('user_id');
    _accessToken = prefs.getString('access_token');

    // 恢复API服务的token
    if (_accessToken != null) {
      ApiService().setAuthToken(_accessToken!);
    }

    // 加载Mikomi用户信息
    final mikomiUserInfoJson = prefs.getString('mikomi_user_info');
    if (mikomiUserInfoJson != null) {
      try {
        _mikomiUserInfo = MikomiUser.fromJson(json.decode(mikomiUserInfoJson));
      } catch (e) {
        debugPrint('解析Mikomi用户信息失败: $e');
      }
    }

    notifyListeners();
  }

  // 保存Mikomi登录信息
  Future<void> saveMikomiLoginInfo({
    required String token,
    required int userId,
    required String account,
    required String nickname,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('user_id', userId);
    await prefs.setString('access_token', token);

    // 设置API服务的token
    ApiService().setAuthToken(token);

    _isLoggedIn = true;
    _userId = userId;
    _accessToken = token;

    // 保存Mikomi用户信息
    _mikomiUserInfo = MikomiUser(
      id: userId,
      account: account,
      nickname: nickname,
      email: email,
    );
    await prefs.setString(
      'mikomi_user_info',
      json.encode(_mikomiUserInfo!.toJson()),
    );

    notifyListeners();
  }

  // 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_id');
    await prefs.remove('access_token');
    await prefs.remove('mikomi_user_info');

    // 清理API服务的token
    ApiService().clearAuthToken();

    _isLoggedIn = false;
    _userId = null;
    _accessToken = null;
    _mikomiUserInfo = null;
    notifyListeners();
  }
}

// Mikomi用户信息
class MikomiUser {
  final int id;
  final String account;
  final String nickname;
  final String email;

  MikomiUser({
    required this.id,
    required this.account,
    required this.nickname,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'account': account, 'nickname': nickname, 'email': email};
  }

  factory MikomiUser.fromJson(Map<String, dynamic> json) {
    return MikomiUser(
      id: json['id'] as int,
      account: json['account'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
    );
  }
}
