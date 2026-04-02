class UaDynamicGeneration {
  String generate() {
    final unix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final minor = (unix % 9) + 1;
    return 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/123.0.$minor.0 Mobile Safari/537.36';
  }
}
