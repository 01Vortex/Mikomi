import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HeroAnimationStyle { standard, fade, scale, rotate }

class AnimationProvider extends ChangeNotifier {
  static const String _heroAnimationKey = 'hero_animation_style';
  static AnimationProvider? _instance;
  HeroAnimationStyle _heroAnimationStyle = HeroAnimationStyle.standard;

  HeroAnimationStyle get heroAnimationStyle => _heroAnimationStyle;

  static AnimationProvider get instance {
    _instance ??= AnimationProvider._();
    return _instance!;
  }

  AnimationProvider._() {
    _loadSettings();
  }

  AnimationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_heroAnimationKey) ?? 'standard';
    _heroAnimationStyle = HeroAnimationStyle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HeroAnimationStyle.standard,
    );
    notifyListeners();
  }

  Future<void> setHeroAnimationStyle(HeroAnimationStyle style) async {
    if (_heroAnimationStyle == style) return;

    _heroAnimationStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_heroAnimationKey, style.name);

    if (_instance != null) {
      _instance!._heroAnimationStyle = style;
      _instance!.notifyListeners();
    }

    notifyListeners();
  }

  static String getAnimationStyleName(HeroAnimationStyle style) {
    switch (style) {
      case HeroAnimationStyle.standard:
        return '标准过渡';
      case HeroAnimationStyle.fade:
        return '淡入淡出';
      case HeroAnimationStyle.scale:
        return '缩放过渡';
      case HeroAnimationStyle.rotate:
        return '旋转过渡';
    }
  }

  static Widget buildHeroFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget as Hero;
    final style = AnimationProvider.instance.heroAnimationStyle;

    switch (style) {
      case HeroAnimationStyle.fade:
        return FadeTransition(opacity: animation, child: toHero.child);
      case HeroAnimationStyle.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: toHero.child,
        );
      case HeroAnimationStyle.rotate:
        return RotationTransition(
          turns: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: ScaleTransition(scale: animation, child: toHero.child),
        );
      case HeroAnimationStyle.standard:
        return toHero.child;
    }
  }
}
