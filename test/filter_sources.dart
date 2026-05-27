import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = 'assets/plugins/online/online.json';
  final outputPath = 'assets/plugins/online/online1.json';

  final jsonStr = File(inputPath).readAsStringSync();
  final root = jsonDecode(jsonStr) as Map<String, dynamic>;
  final sources = (root['exportedMediaSourceDataList']
          as Map<String, dynamic>?)?['mediaSources'] as List<dynamic>? ??
      const [];

  // 提取所有搜索域名
  final domains = <String, bool>{};
  for (final s in sources) {
    if (s is! Map<String, dynamic>) continue;
    if (s['factoryId'] != 'web-selector') continue;
    final args = s['arguments'] as Map<String, dynamic>?;
    if (args == null) continue;
    final search = args['searchConfig'] as Map<String, dynamic>? ?? {};
    final searchUrl = search['searchUrl'] as String? ?? '';
    if (searchUrl.isEmpty) continue;
    try {
      domains[Uri.parse(searchUrl).host] = false;
    } catch (_) {}
  }

  print('检测 ${domains.length} 个域名...\n');

  // 并发检测（限制 10 个并发）
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 5);
  var pending = 0;

  final completer = Completer<void>();
  for (final domain in domains.keys.toList()) {
    pending++;
    _check(client, domain).then((alive) {
      domains[domain] = alive;
      print(alive ? '✅ $domain' : '❌ $domain');
      pending--;
      if (pending == 0 && !completer.isCompleted) completer.complete();
    });
  }
  await completer.future;
  client.close();

  // 过滤存活源
  final aliveSources = <Map<String, dynamic>>[];
  for (final s in sources) {
    if (s is! Map<String, dynamic>) continue;
    if (s['factoryId'] != 'web-selector') continue;
    final args = s['arguments'] as Map<String, dynamic>?;
    if (args == null) continue;
    final search = args['searchConfig'] as Map<String, dynamic>? ?? {};
    final searchUrl = search['searchUrl'] as String? ?? '';
    if (searchUrl.isEmpty) continue;
    try {
      if (domains[Uri.parse(searchUrl).host] == true) {
        aliveSources.add(s);
      }
    } catch (_) {}
  }

  // 写输出
  final output = {
    'exportedMediaSourceDataList': {'mediaSources': aliveSources}
  };
  File(outputPath).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));

  final totalSources = sources.where((s) => s is Map && s['factoryId'] == 'web-selector').length;
  print('\n$totalSources 个源 → ${aliveSources.length} 个存活 → $outputPath');
}

Future<bool> _check(HttpClient client, String domain) async {
  try {
    final req = await client.getUrl(Uri.parse('https://$domain'));
    final res = await req.close();
    return res.statusCode < 500;
  } catch (_) {
    return false;
  }
}
