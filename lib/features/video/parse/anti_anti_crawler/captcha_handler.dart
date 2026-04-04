import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class CaptchaHandler implements AntiAntiCrawler {
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
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {}

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {
    if (context.controller == null) return;

    await _tryClickCaptchaButton(context);
    await _waitForChallengeToPass(context);
  }

  Future<void> _tryClickCaptchaButton(AntiAntiCrawlerContext context) async {
    final controller = context.controller;
    if (controller == null) return;

    final xpath = context.options.captchaButtonXpath.trim();
    if (xpath.isNotEmpty) {
      final clicked = await _clickByXpath(controller, xpath);
      if (clicked) return;
    }

    await controller.evaluateJavascript(
      source: '''
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

        const selectors = [
          'input[type="submit"]',
          'button[type="submit"]',
          'button',
          '.verify-btn',
          '.verify-button',
          '.captcha-btn',
          '.btn-verify',
          '[data-role="verify"]',
          '[data-action="verify"]',
          '.geetest_btn',
          '.geetest_commit',
          '.ctp-checkbox-label',
          '.cf-turnstile',
          '#challenge-stage button'
        ];

        for (const selector of selectors) {
          const nodes = document.querySelectorAll(selector);
          for (const node of nodes) {
            const text = (node.innerText || node.value || '').trim().toLowerCase();
            if (!text ||
                text.includes('verify') ||
                text.includes('验证') ||
                text.includes('继续') ||
                text.includes('提交') ||
                text.includes('confirm') ||
                text.includes('continue') ||
                text.includes('human')) {
              if (clickNode(node)) return true;
            }
          }
        }

        const frame = document.querySelector('iframe[src*="turnstile"], iframe[title*="challenge"], iframe[src*="captcha"]');
        if (frame) {
          try {
            const rect = frame.getBoundingClientRect();
            const target = document.elementFromPoint(rect.left + Math.min(rect.width / 2, 24), rect.top + Math.min(rect.height / 2, 24));
            if (clickNode(target)) return true;
          } catch (_) {}
        }

        return false;
      })();
    ''',
    );
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

  Future<void> _waitForChallengeToPass(AntiAntiCrawlerContext context) async {
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

  @override
  void dispose() {}
}
