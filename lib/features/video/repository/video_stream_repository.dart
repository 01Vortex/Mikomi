class VideoStreamRepository {
  final Map<String, String> _cache = <String, String>{};

  String? getCachedStreamUrl(String key) {
    final value = _cache[key];
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  void saveCachedStreamUrl(String key, String url) {
    if (key.trim().isEmpty || url.trim().isEmpty) return;
    _cache[key] = url;
  }

  void removeCachedStreamUrl(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}
