import 'package:flutter/material.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/features/auth/service/mikomi_register_service.dart';
import 'dart:async';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final MikomiRegisterService _registerService = MikomiRegisterService();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _codeFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendVerificationCode() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入邮箱')));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的邮箱地址')));
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      await _registerService.sendVerificationCode(_emailController.text);

      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('验证码已发送，请查收邮件')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入昵称')));
      return;
    }

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入邮箱')));
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入密码')));
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('密码长度至少6位')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
      return;
    }

    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入验证码')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _registerService.register(
        nickname: _nicknameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        code: _codeController.text,
      );

      if (mounted && response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注册成功！账号: ${response.user.account}')),
        );
        Navigator.pop(context);
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
                  const SizedBox(height: 32),
                  _buildNicknameField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 16),
                  _buildCodeField(),
                  const SizedBox(height: 32),
                  _buildRegisterButton(),
                  const SizedBox(height: 24),
                  _buildLoginPrompt(),
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
          '创建账号',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '填写信息以完成注册',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNicknameField() {
    return TextField(
      controller: _nicknameController,
      focusNode: _nicknameFocus,
      decoration: InputDecoration(
        labelText: '昵称',
        hintText: '请输入昵称（3-20个字符）',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: context.colors.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _emailFocus.requestFocus(),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: '邮箱',
        hintText: '请输入邮箱地址',
        prefixIcon: const Icon(Icons.email_outlined),
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
        hintText: '请输入密码（至少6位）',
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
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocus,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: '确认密码',
        hintText: '请再次输入密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: context.colors.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
      ),
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _codeFocus.requestFocus(),
    );
  }

  Widget _buildCodeField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeController,
            focusNode: _codeFocus,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '验证码',
              hintText: '请输入邮箱验证码',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: context.colors.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleRegister(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: FilledButton(
            onPressed: _countdown > 0 || _isSendingCode
                ? null
                : _sendVerificationCode,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSendingCode
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _countdown > 0 ? '${_countdown}s' : '发送验证码',
                    style: const TextStyle(fontSize: 13),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _handleRegister,
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
              '注册',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '已有账号？',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '立即登录',
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
