import 'dart:convert';
import 'dart:io';

void main() async {
  final jsonStr = File('assets/plugins/online/online.json').readAsStringSync();
  final root = jsonDecode(jsonStr) as Map<String, dynamic>;
  final sources = (root['exportedMediaSourceDataList']
          as Map<String, dynamic>?)?['mediaSources'] as List<dynamic>? ??
      const [];

  final domains = <String>{};
  final sourceNames = <String, String>{}; // name → searchUrl

  for (final s in sources) {
    if (s is! Map<String, dynamic>) continue;
    if (s['factoryId'] != 'web-selector') continue;
    final args = s['arguments'] as Map<String, dynamic>?;
    if (args == null) continue;
    final name = args['name'] as String? ?? '';
    final search = args['searchConfig'] as Map<String, dynamic>? ?? {};
    final searchUrl = search['searchUrl'] as String? ?? '';
    if (searchUrl.isEmpty) continue;

    sourceNames[name] = searchUrl;
    try {
      final uri = Uri.parse(searchUrl);
      domains.add(uri.host);
    } catch (_) {}
  }

  print('共 ${domains.length} 个域名，${sourceNames.length} 个源\n');
  print('=== 检测中 ===\n');

  final alive = <String>[];
  final dead = <String>[];

  for (final domain in domains) {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final req = await client.getUrl(Uri.parse('https://$domain'));
      final res = await req.close();
      alive.add(domain);
      print('✅ $domain (${res.statusCode})');
    } catch (e) {
      dead.add(domain);
      print('❌ $domain');
    }
  }

  print('\n=== 结果 ===');
  print('存活: ${alive.length}  失效: ${dead.length}');

  print('\n失效域名对应的源:');
  for (final entry in sourceNames.entries) {
    try {
      final host = Uri.parse(entry.value).host;
      if (dead.contains(host)) {
        print('  ❌ ${entry.key} → ${entry.value}');
      }
    } catch (_) {}
  }
}
