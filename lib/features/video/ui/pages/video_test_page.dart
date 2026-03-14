import 'package:flutter/material.dart';
import 'package:mikomi/features/video/data/services/video_plugin_service.dart';
import 'package:mikomi/features/video/data/repositories/video_source_repository.dart';
import 'package:mikomi/shared/widgets/message_dialog.dart';

class VideoTestPage extends StatefulWidget {
  const VideoTestPage({super.key});

  @override
  State<VideoTestPage> createState() => _VideoTestPageState();
}

class _VideoTestPageState extends State<VideoTestPage> {
  final VideoPluginService _pluginService = VideoPluginService();
  final VideoSourceRepository _videoSourceRepo = VideoSourceRepository();
  final TextEditingController _keywordController = TextEditingController();

  bool _isLoading = false;
  String _testResult = '';
  String? _selectedPlugin;

  @override
  void initState() {
    super.initState();
    _initializePlugins();
  }

  Future<void> _initializePlugins() async {
    setState(() => _isLoading = true);
    try {
      await _pluginService.initialize();
      setState(() {
        _isLoading = false;
        _testResult = '插件初始化成功\n共加载 ${_pluginService.plugins.length} 个插件:\n';
        for (var plugin in _pluginService.plugins) {
          _testResult += '- ${plugin.name}\n';
          _testResult += '  baseURL: ${plugin.baseURL}\n';
          _testResult += '  searchURL: ${plugin.searchURL}\n\n';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = '插件初始化失败: $e';
      });
    }
  }

  Future<void> _testSearch() async {
    if (_keywordController.text.isEmpty) {
      if (mounted && context.mounted) {
        MessageDialog.warning(context, '请输入搜索关键词');
      }
      return;
    }

    if (_selectedPlugin == null) {
      if (mounted && context.mounted) {
        MessageDialog.warning(context, '请选择视频源');
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult =
          '正在搜索: ${_keywordController.text}\n使用插件: $_selectedPlugin\n\n';
    });

    try {
      // 先获取插件配置
      final plugin = _pluginService.getPluginByName(_selectedPlugin!);
      if (plugin == null) {
        setState(() {
          _isLoading = false;
          _testResult += '插件未找到';
        });
        return;
      }

      _testResult += '=== 插件配置 ===\n';
      _testResult += 'baseURL: ${plugin.baseURL}\n';
      _testResult += 'searchURL: ${plugin.searchURL}\n';
      _testResult += 'searchList: ${plugin.searchList}\n';
      _testResult += 'searchName: ${plugin.searchName}\n';
      _testResult += 'searchResult: ${plugin.searchResult}\n';
      _testResult += 'chapterRoads: ${plugin.chapterRoads}\n';
      _testResult += 'chapterResult: ${plugin.chapterResult}\n\n';

      setState(() {});

      final episodes = await _videoSourceRepo
          .searchAndGetEpisodes(_keywordController.text, _selectedPlugin!)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              return [];
            },
          );

      setState(() {
        _isLoading = false;
        if (episodes.isEmpty) {
          _testResult += '\n未找到任何结果\n';
          _testResult += '可能原因:\n';
          _testResult += '1. XPath选择器不正确\n';
          _testResult += '2. 网站结构已变化\n';
          _testResult += '3. 网络请求失败\n';
          _testResult += '4. 关键词没有匹配结果\n';
        } else {
          _testResult += '\n找到 ${episodes.length} 集:\n\n';
          for (var ep in episodes) {
            _testResult += '第 ${ep.number} 集: ${ep.title ?? "无标题"}\n';
            _testResult += 'URL: ${ep.url}\n\n';
          }
        }
      });

      if (mounted && context.mounted) {
        if (episodes.isEmpty) {
          MessageDialog.warning(context, '未找到任何结果，请查看调试信息');
        } else {
          MessageDialog.success(context, '找到 ${episodes.length} 集');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult += '\n搜索失败: $e';
      });
      if (mounted && context.mounted) {
        MessageDialog.error(context, '搜索失败: $e');
      }
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('视频源测试')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '插件信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_pluginService.plugins.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '选择视频源',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedPlugin,
                        items: _pluginService.plugins.map((plugin) {
                          return DropdownMenuItem(
                            value: plugin.name,
                            child: Text(plugin.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPlugin = value);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '搜索测试',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keywordController,
                      decoration: const InputDecoration(
                        labelText: '搜索关键词',
                        hintText: '例如: 葬送的芙莉莲',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testSearch,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('开始搜索'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '测试结果',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _testResult.isEmpty ? '等待测试...' : _testResult,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
