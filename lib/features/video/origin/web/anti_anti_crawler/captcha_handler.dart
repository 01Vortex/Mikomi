import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/origin/web/anti_anti_crawler/strategy.dart';

class CaptchaHandler implements AntiCrawlerStrategy {
  static const Duration _captchaWaitStep = Duration(seconds: 2);
  static const Duration _captchaWaitTimeout = Duration(seconds: 18);

  const CaptchaHandler();

  bool detect(String html) {
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

  @override
  Future<void> onBeforeLoad(AntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: _autoClickScript);
  }

  @override
  Future<void> onAfterLoad(AntiCrawlerContext context) async {
    if (context.controller == null) return;

    await _tryClickCaptchaButton(context);
    await _waitForChallengeToPass(context);
  }

  Future<void> _tryClickCaptchaButton(AntiCrawlerContext context) async {
    final controller = context.controller;
    if (controller == null) return;

    final xpath = context.options.captchaButtonXpath.trim();
    if (xpath.isNotEmpty) {
      final clicked = await _clickByXpath(controller, xpath);
      if (clicked) return;
    }

    await controller.evaluateJavascript(source: _autoClickScript);
  }

  Future<bool> _clickByXpath(
    InAppWebViewController controller,
    String xpath,
  ) async {
    final result = await controller.evaluateJavascript(
      source:
          '''
      (function() {
        function clickNode(node) {
          if (!node) return false;
          try {
            node.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
            node.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
            node.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
            node.click();
            return true;
          } catch (_) {
            return false;
          }
        }

        try {
          const node = document.evaluate(
            ${_jsString(xpath)},
            document,
            null,
            XPathResult.FIRST_ORDERED_NODE_TYPE,
            null,
          ).singleNodeValue;
          return clickNode(node);
        } catch (_) {
          return false;
        }
      })();
    ''',
    );
    return result == true;
  }

  Future<void> _waitForChallengeToPass(AntiCrawlerContext context) async {
    final controller = context.controller;
    if (controller == null) return;

    final deadline = DateTime.now().add(_captchaWaitTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final html = await _readHtml(controller);
      if (html.isEmpty) {
        await Future.delayed(_captchaWaitStep);
        continue;
      }
      if (!detect(html)) {
        return;
      }
      await _tryClickCaptchaButton(context);
      await Future.delayed(_captchaWaitStep + _randomJitter());
    }

    debugPrint(
      '[CaptchaHandler] captcha challenge still active after wait timeout',
    );
  }

  Future<String> _readHtml(InAppWebViewController controller) async {
    final html = await controller.evaluateJavascript(
      source:
          'document.documentElement ? document.documentElement.outerHTML : "";',
    );
    return html?.toString() ?? '';
  }

  Duration _randomJitter() {
    final random = Random();
    return Duration(milliseconds: 200 + random.nextInt(400));
  }

  static String _jsString(String value) {
    return jsonEncode(value);
  }

  static const String _autoClickScript = r'''
    (function() {
      function visible(node) {
        if (!node) return false;
        const style = window.getComputedStyle(node);
        const rect = node.getBoundingClientRect();
        return style.display !== 'none' &&
          style.visibility !== 'hidden' &&
          style.pointerEvents !== 'none' &&
          rect.width > 0 &&
          rect.height > 0;
      }

      function clickNode(node) {
        if (!node || !visible(node)) return false;
        try {
          node.scrollIntoView({ block: 'center', inline: 'center' });
          const rect = node.getBoundingClientRect();
          const x = rect.left + rect.width / 2;
          const y = rect.top + rect.height / 2;
          ['pointerover', 'pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'].forEach(type => {
            node.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y }));
          });
          if (typeof node.click === 'function') node.click();
          return true;
        } catch (_) {
          return false;
        }
      }

      const selectors = [
        'input[type="submit"]',
        'input[type="button"]',
        'button[type="submit"]',
        'button',
        '[role="button"]',
        'a.btn',
        '.btn',
        '.button',
        '.verify-btn',
        '.verify-button',
        '.captcha-btn',
        '.btn-verify',
        '.confirm',
        '.confirm-btn',
        '.continue',
        '.continue-btn',
        '[data-role="verify"]',
        '[data-action="verify"]',
        '[data-action="confirm"]',
        '.geetest_btn',
        '.geetest_commit',
        '.ctp-checkbox-label',
        '.cf-turnstile',
        '#challenge-stage button'
      ];

      const keywords = [
        'verify', 'captcha', 'confirm', 'continue', 'submit', 'human', 'allow', 'enter', 'start', 'ok',
        '验证', '校验', '确认', '确定', '继续', '提交', '进入', '同意', '允许', '开始', '我知道', '不是机器人'
      ];

      for (const selector of selectors) {
        const nodes = document.querySelectorAll(selector);
        for (const node of nodes) {
          const text = ((node.innerText || node.textContent || node.value || node.getAttribute('aria-label') || '') + '').trim().toLowerCase();
          if (!text || keywords.some(k => text.includes(k))) {
            if (clickNode(node)) return true;
          }
        }
      }

      const frame = document.querySelector('iframe[src*="turnstile"], iframe[title*="challenge"], iframe[src*="captcha"], iframe[src*="verify"]');
      if (frame && visible(frame)) {
        try {
          const rect = frame.getBoundingClientRect();
          const target = document.elementFromPoint(rect.left + Math.min(rect.width / 2, 28), rect.top + Math.min(rect.height / 2, 28));
          if (clickNode(target)) return true;
        } catch (_) {}
      }

      return false;
    })();
  ''';

  @override
  void dispose() {}
}
