import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 反反爬虫结果
class AacResult {
  final bool success;
  final String? html;
  final String? cookie;
  final String? cfClearance;
  final String message;

  const AacResult({
    required this.success,
    this.html,
    this.cookie,
    this.cfClearance,
    this.message = '',
  });
}

/// 反反爬虫服务
/// 策略优先级：
///   1. 随机化 UA + 请求头伪装
///   2. 随机延迟（模拟人类行为）
///   3. 隐身 WebView（注入 stealth JS，抹除 webdriver/automation 特征）
///   4. Cookie 持久化回注 Dio
///   5. Cloudflare Turnstile / 5s challenge 自动等待
///   6. 最多重试 3 次，指数退避
class AntiAntiCrawlerService {
  static const int _maxRetries = 3;
  static const int _baseDelayMs = 800;

  static final _random = Random();

  /// 桌面端 UA 池
  static const _desktopUAs = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0',
  ];

  /// 移动端 UA 池
  static const _mobileUAs = [
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
  ];

  static String get _randomUA => _random.nextBool()
      ? _desktopUAs[_random.nextInt(_desktopUAs.length)]
      : _mobileUAs[_random.nextInt(_mobileUAs.length)];

  /// stealth.js 核心：抹除自动化特征
  static const _stealthScript = """
(function(){
  // 1. 抹除 webdriver
  Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
  // 2. 修复 chrome runtime
  if (!window.chrome) { window.chrome = { runtime: {} }; }
  // 3. 修复 permissions
  const origQuery = window.navigator.permissions.query;
  window.navigator.permissions.query = (params) => (
    params.name === 'notifications'
      ? Promise.resolve({ state: Notification.permission })
      : origQuery(params)
  );
  // 4. 修复 plugins 长度
  Object.defineProperty(navigator, 'plugins', { get: () => [1,2,3,4,5] });
  // 5. 修复 languages
  Object.defineProperty(navigator, 'languages', { get: () => ['zh-CN','zh','en'] });
  // 6. 抹除 automation 相关属性
  ['__webdriver_evaluate','__selenium_evaluate','__webdriver_script_func',
   '__webdriver_script_fn','__fxdriver_evaluate','__driver_unwrapped',
   '__webdriver_unwrapped','__driver_evaluate','__selenium_unwrapped',
   '__fxdriver_unwrapped','_selenium','callSelenium','_Selenium_IDE_Recorder',
   '__selenium_ids','__webdriverFunc','_phantom','__phantomas',
   'domAutomation','domAutomationController'].forEach(k => {
    try { Object.defineProperty(window, k, { get: () => undefined }); } catch(_) {}
  });
  // 7. 模拟真实屏幕参数
  Object.defineProperty(screen, 'availWidth', { get: () => 1920 });
  Object.defineProperty(screen, 'availHeight', { get: () => 1080 });
})();
""";

  /// 是否看起来像反爬/验证页
  static bool looksLikeBlocked(String html) {
    final lower = html.toLowerCase();
    return lower.contains('captcha') ||
        lower.contains('验证码') ||
        lower.contains('verify') ||
        lower.contains('人机验证') ||
        lower.contains('geetest') ||
        lower.contains('turnstile') ||
        lower.contains('smart-verify') ||
        lower.contains('verify-panel') ||
        lower.contains('cf-browser-verification') ||
        lower.contains('checking your browser') ||
        lower.contains('just a moment') ||
        lower.contains('ddos-guard') ||
        lower.contains('__ddg') ||
        lower.contains('robot or human');
  }

  /// 构造伪装请求头
  static Map<String, String> buildHeaders(String baseUrl, {String? ua}) {
    final chosenUA = ua ?? _randomUA;
    return {
      'User-Agent': chosenUA,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
      'Referer': baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
    };
  }

  /// 随机延迟（模拟人类）
  static Future<void> _humanDelay([int baseMs = _baseDelayMs]) async {
    final jitter = _random.nextInt(600);
    await Future.delayed(Duration(milliseconds: baseMs + jitter));
  }

  /// 用隐身 WebView 获取 HTML（自动等待 CF 5s challenge）
  /// 返回 (html, cookieString)
  static Future<(String?, String?)> fetchWithStealthWebView(
    String url, {
    String? ua,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final completer = Completer<(String?, String?)>();
    HeadlessInAppWebView? webView;
    Timer? timeoutTimer;
    String chosenUA = ua ?? _randomUA;

    webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(url),
        headers: buildHeaders(Uri.parse(url).origin, ua: chosenUA),
      ),
      initialSettings: InAppWebViewSettings(
        userAgent: chosenUA,
        javaScriptEnabled: true,
        cacheEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        geolocationEnabled: false,
        safeBrowsingEnabled: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        upgradeKnownHostsToHTTPS: false,
      ),
      onWebViewCreated: (ctrl) async {
        // 注入 stealth 脚本
        await ctrl.addUserScripts(userScripts: [
          UserScript(
            source: _stealthScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
        ]);
      },
      onLoadStop: (ctrl, loadedUrl) async {
        if (completer.isCompleted) return;
        try {
          final html = await ctrl.getHtml();
          if (html == null || looksLikeBlocked(html)) {
            // 还在 challenge 中，继续等待
            return;
          }
          // 收集 cookie
          final cookieManager = CookieManager.instance();
          final cookies = await cookieManager.getCookies(url: WebUri(url));
          final cookieStr = cookies.isNotEmpty
              ? cookies.map((c) => '${c.name}=${c.value}').join('; ')
              : null;
          completer.complete((html, cookieStr));
        } catch (e) {
          debugPrint('[AAC] onLoadStop error: $e');
        }
      },
      onReceivedServerTrustAuthRequest: (ctrl, challenge) async =>
          ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED),
    );

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete((null, null));
    });

    try {
      await webView.run();
      final result = await completer.future;
      return result;
    } finally {
      timeoutTimer.cancel();
      await webView.dispose();
    }
  }

  /// 主入口：带反反爬的 HTML 获取
  /// [dio] 传入当前 Dio 实例，成功后会自动注入 cookie
  /// [ua] 为空则随机选取
  static Future<AacResult> fetch(
    String url,
    Dio dio, {
    String? ua,
    CancelToken? cancelToken,
  }) async {
    String chosenUA = ua ?? _randomUA;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        // 随机延迟，首次较短
        if (attempt > 1) {
          await _humanDelay(_baseDelayMs * (1 << (attempt - 1)));
        } else {
          await _humanDelay(200);
        }

        // 第一步：先用 Dio 试探（轻量快速）
        final response = await dio.get(
          url,
          cancelToken: cancelToken,
          options: Options(headers: buildHeaders(
            Uri.parse(url).origin,
            ua: chosenUA,
          )),
        );

        if (response.statusCode == 200) {
          final html = response.data.toString();
          if (!looksLikeBlocked(html)) {
            return AacResult(success: true, html: html, message: '直接请求成功 (attempt $attempt)');
          }
          debugPrint('[AAC] Dio blocked on attempt $attempt, switching to stealth WebView');
        }

        // 第二步：Dio 被拦截，用隐身 WebView 突破
        chosenUA = _randomUA; // 换个 UA 再试
        final (html, cookieStr) = await fetchWithStealthWebView(
          url,
          ua: chosenUA,
          timeout: Duration(seconds: 15 + attempt * 5),
        );

        if (html != null && html.isNotEmpty && !looksLikeBlocked(html)) {
          // 把 cookie 注回 Dio，后续请求复用
          if (cookieStr != null) {
            dio.options.headers['cookie'] = cookieStr;
            dio.options.headers['User-Agent'] = chosenUA;
          }
          return AacResult(
            success: true,
            html: html,
            cookie: cookieStr,
            message: 'Stealth WebView 突破成功 (attempt $attempt)',
          );
        }

        debugPrint('[AAC] Stealth WebView still blocked on attempt $attempt');
        // 换 UA 继续重试
        chosenUA = _randomUA;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          return const AacResult(success: false, message: '已取消');
        }
        debugPrint('[AAC] DioException attempt $attempt: ${e.message}');
        if (attempt == _maxRetries) {
          return AacResult(success: false, message: '请求失败：${e.message}');
        }
      } catch (e) {
        debugPrint('[AAC] Error attempt $attempt: $e');
        if (attempt == _maxRetries) {
          return AacResult(success: false, message: '未知错误：$e');
        }
      }
    }

    return const AacResult(success: false, message: '达到最大重试次数，反爬突破失败');
    }}
