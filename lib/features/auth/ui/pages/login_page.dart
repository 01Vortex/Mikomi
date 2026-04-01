import 'package:flutter/material.dart';
import 'package:mikomi/shared/theme_extensions.dart';
import 'package:mikomi/features/auth/service/bangumi_login_service.dart';
import 'package:mikomi/features/auth/service/mikomi_login_service.dart';
import 'package:mikomi/features/auth/service/mikomi_oauth_service.dart';
import 'package:mikomi/features/auth/ui/pages/register_page.dart';
import 'package:mikomi/core/services/auth_service.dart';
import 'package:mikomi/core/services/navigation_service.dart';
import 'package:mikomi/shared/message_dialog.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _accountFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final BangumiLoginService _bangumiService = BangumiLoginService();
  final MikomiLoginService _mikomiLoginService = MikomiLoginService();
  final MikomiOAuthService _mikomiOAuthService = MikomiOAuthService();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // 监听Deep Link
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('收到Deep Link: $uri');

    // 检查是否是Bangumi OAuth回调
    if (uri.scheme == 'mikomi' &&
        uri.host == 'auth' &&
        uri.path == '/bangumi') {
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      if (code != null) {
        await _exchangeBangumiToken(code, state);
      }
    }
  }

  Future<void> _exchangeBangumiToken(String code, String? state) async {
    try {
      setState(() => _isLoading = true);

      final token = await _bangumiService.exchangeToken(code, state: state);

      if (token != null && mounted) {
        // 获取Bangumi用户信息
        final bangumiUser = await _bangumiService.getCurrentUser(
          token.accessToken,
        );

        if (bangumiUser != null && mounted) {
          // 调用后端OAuth登录接口
          final response = await _mikomiOAuthService.oauthLogin(
            provider: 'bangumi',
            providerUserId: bangumiUser.id.toString(),
            providerUsername: bangumiUser.username,
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresIn: token.expiresIn,
            nickname: bangumiUser.nickname,
            avatarUrl: bangumiUser.avatarUrl,
            bio: bangumiUser.sign,
          );

          if (response != null && mounted) {
            // 保存Mikomi登录信息
            final authService = context.read<AuthService>();
            await authService.saveMikomiLoginInfo(
              token: response.token,
              userId: response.user.id,
              account: response.user.account,
              nickname: response.user.nickname,
              email: response.user.email,
            );

            if (mounted) {
              String message = '登录成功！欢迎 ${response.user.nickname}';
              if (response.isNewUser && response.mikomiAccount != null) {
                message += '\n您的Mikomi账号：${response.mikomiAccount}';
              }

              MessageDialog.success(context, message);

              // 切换到个人页tab
              context.read<NavigationService>().switchToMyPage();

              // 返回到主页
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登录失败，请重试')));
      }
    } catch (e) {
      debugPrint('Bangumi登录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _accountController.dispose();
    _passwordController.dispose();
    _accountFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_accountController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入账号和密码')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _mikomiLoginService.login(
        account: _accountController.text,
        password: _passwordController.text,
      );

      if (mounted && response != null) {
        // 保存Mikomi登录信息到AuthService
        final authService = context.read<AuthService>();
        await authService.saveMikomiLoginInfo(
          token: response.token,
          userId: response.user.id,
          account: response.user.account,
          nickname: response.user.nickname,
          email: response.user.email,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录成功！欢迎 ${response.user.nickname}')),
          );

          // 切换到个人页tab
          context.read<NavigationService>().switchToMyPage();

          // 返回到主页
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 48),
                  _buildWelcomeText(),
                  const SizedBox(height: 40),
                  _buildUsernameField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 12),
                  _buildForgotPassword(),
                  const SizedBox(height: 32),
                  _buildLoginButton(),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildSocialLogin(),
                  const SizedBox(height: 32),
                  _buildSignUpPrompt(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: context.colors.surface.withValues(
                    alpha: 0.9,
                  ),
                  foregroundColor: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.play_circle_outline,
            size: 48,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Mikomi',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '欢迎回来',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '登录以继续使用',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _accountController,
      focusNode: _accountFocus,
      decoration: InputDecoration(
        labelText: '账号/邮箱',
        hintText: '请输入账号或邮箱',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: context.colors.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _passwordFocus.requestFocus(),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '请输入密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: context.colors.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('忘记密码功能开发中')));
        },
        child: Text(
          '忘记密码？',
          style: TextStyle(fontSize: 14, color: context.colors.primary),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              '登录',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '或',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: context.colors.outlineVariant)),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          icon: Icons.tv,
          label: 'Bangumi',
          onTap: _handleBangumiLogin,
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          label: 'Google',
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Google登录开发中')));
          },
        ),
      ],
    );
  }

  Future<void> _handleBangumiLogin() async {
    try {
      // 生成随机state用于防止CSRF攻击
      final state = DateTime.now().millisecondsSinceEpoch.toString();

      // 启动OAuth授权流程
      final success = await _bangumiService.startAuthorization(state: state);

      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开Bangumi授权页面')));
      }

      // TODO: 需要实现回调处理逻辑
      // 1. 配置Deep Link接收回调
      // 2. 从回调URL中提取code
      // 3. 调用exchangeToken获取access token
      // 4. 保存token并更新登录状态
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bangumi登录失败: $e')));
      }
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: context.colors.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账号？',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
          child: Text(
            '立即注册',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
