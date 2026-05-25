class ParsingCookieManager {
  final Map<String, String> _cookieStore = {};

  void save(String key, String value) {
    _cookieStore[key] = value;
  }

  String? read(String key) {
    return _cookieStore[key];
  }

  void clear() {
    _cookieStore.clear();
  }
}
