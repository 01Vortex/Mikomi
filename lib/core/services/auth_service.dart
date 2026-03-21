import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikomi/features/auth/service/bangumi_login_service.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  int? _userId;
  String? _accessToken;
  String? _refreshToken;
  BangumiUser? _userInfo;

  bool get isLoggedIn => _isLoggedIn;
  int? get userId => _userId;
  String? get accessToken => _accessToken;
  BangumiUser? get userInfo => _userInfo;

  // 初始化，从本地存储加载登录状态
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _userId = prefs.getInt('user_id');
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');

    // 加载用户信息
    final userInfoJson = prefs.getString('user_info');
    if (userInfoJson != null) {
      try {
        _userInfo = BangumiUser.fromJson(json.decode(userInfoJson));
      } catch (e) {
        debugPrint('解析用户信息失败: $e');
      }
    }

    notifyListeners();
  }

  // 保存登录信息
  Future<void> saveLoginInfo(BangumiAuthToken token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('user_id', token.userId);
    await prefs.setString('access_token', token.accessToken);
    await prefs.setString('refresh_token', token.refreshToken);
    await prefs.setInt('token_expires_in', token.expiresIn);
    await prefs.setInt(
      'token_expires_at',
      DateTime.now().millisecondsSinceEpoch + (token.expiresIn * 1000),
    );

    _isLoggedIn = true;
    _userId = token.userId;
    _accessToken = token.accessToken;
    _refreshToken = token.refreshToken;

    // 获取用户信息
    await fetchUserInfo();

    notifyListeners();
  }

  // 获取并保存用户信息
  Future<void> fetchUserInfo() async {
    if (_accessToken == null) return;

    try {
      final bangumiService = BangumiLoginService();
      final userInfo = await bangumiService.getCurrentUser(_accessToken!);

      if (userInfo != null) {
        _userInfo = userInfo;

        // 保存到本地
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_info', json.encode(userInfo.toJson()));

        notifyListeners();
      }
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
    }
  }

  // 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_id');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expires_in');
    await prefs.remove('token_expires_at');
    await prefs.remove('user_info');

    _isLoggedIn = false;
    _userId = null;
    _accessToken = null;
    _refreshToken = null;
    _userInfo = null;
    notifyListeners();
  }

  // 检查token是否过期
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt('token_expires_at');
    if (expiresAt == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= expiresAt;
  }

  // 刷新token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final bangumiService = BangumiLoginService();
      final newToken = await bangumiService.refreshToken(_refreshToken!);

      if (newToken != null) {
        await saveLoginInfo(newToken);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('刷新Token失败: $e');
      return false;
    }
  }
}
