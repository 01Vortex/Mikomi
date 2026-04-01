import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_shop_service.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/shared/message_dialog.dart';

class PluginShopPage extends StatefulWidget {
  const PluginShopPage({super.key});

  @override
  State<PluginShopPage> createState() => _PluginShopPageState();
}

class _PluginShopPageState extends State<PluginShopPage> {
  final PluginShopService _httpService = PluginShopService();
  final VideoPluginManager _pluginManager = VideoPluginManager();
  late Future<List<PluginHTTPItem>> _pluginListFuture;
  bool _sortByName = false;

  @override
  void initState() {
    super.initState();
    _pluginListFuture = _httpService.getPluginList();
  }

  void _toggleSort() {
    setState(() {
      _sortByName = !_sortByName;
    });
  }

  void _handleRefresh() {
    setState(() {
      _pluginListFuture = _httpService.getPluginList();
    });
  }

  String _getPluginStatus(PluginHTTPItem item) {
    final plugin = _pluginManager.getPluginByName(item.name);
    if (plugin == null) {
      return '安装';
    }
    if (plugin.version == item.version) {
      return '已安装';
    }
    return '更新';
  }

  Future<void> _installPlugin(PluginHTTPItem item) async {
    MessageDialog.info(context, '正在安装...');

    final plugin = await _httpService.getPlugin(item.name);
    if (plugin != null) {
      await _pluginManager.updatePlugin(plugin);
      if (mounted) {
        MessageDialog.success(context, '安装成功');
        setState(() {});
      }
    } else {
      if (mounted) {
        MessageDialog.error(context, '安装失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('插件商店'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleSort,
            tooltip: _sortByName ? '按名称排序' : '按更新时间排序',
            icon: Icon(_sortByName ? Icons.sort_by_alpha : Icons.access_time),
          ),
          IconButton(
            onPressed: _handleRefresh,
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<PluginHTTPItem>>(
        future: _pluginListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '无法访问插件商店',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          var plugins = snapshot.data!;

          if (_sortByName) {
            plugins.sort((a, b) =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else {
            plugins.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plugins.length,
            itemBuilder: (context, index) {
              final plugin = plugins[index];
              final status = _getPluginStatus(plugin);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plugin.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.secondary,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'v${plugin.version}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        plugin.useNativePlayer
                                            ? 'native'
                                            : 'webview',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onPrimary,
                                        ),
                                      ),
                                    ),
                                    if (plugin.antiCrawlerEnabled) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.tertiary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'captcha',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onTertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: status == '已安装'
                                ? null
                                : () => _installPlugin(plugin),
                            child: Text(status),
                          ),
                        ],
                      ),
                      if (plugin.lastUpdate > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '更新时间: ${DateTime.fromMillisecondsSinceEpoch(plugin.lastUpdate).toString().split('.')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
