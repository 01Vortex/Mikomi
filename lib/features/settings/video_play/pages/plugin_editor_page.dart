import 'package:flutter/material.dart';
import 'package:mikomi/core/models/video_plugin.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';

class PluginEditorPage extends StatefulWidget {
  final VideoPlugin? plugin;

  const PluginEditorPage({super.key, this.plugin});

  @override
  State<PluginEditorPage> createState() => _PluginEditorPageState();
}

class _PluginEditorPageState extends State<PluginEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final VideoPluginManager _pluginManager = VideoPluginManager();

  late TextEditingController _nameController;
  late TextEditingController _versionController;
  late TextEditingController _baseURLController;
  late TextEditingController _searchURLController;
  late TextEditingController _searchListController;
  late TextEditingController _searchNameController;
  late TextEditingController _searchResultController;
  late TextEditingController _chapterRoadsController;
  late TextEditingController _chapterResultController;
  late TextEditingController _userAgentController;
  late TextEditingController _refererController;

  late bool _multiSources;
  late bool _useWebview;
  late bool _usePost;
  late bool _useLegacyParser;
  late bool _adBlocker;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.plugin != null;

    final plugin = widget.plugin ?? VideoPlugin.fromTemplate();

    _nameController = TextEditingController(text: plugin.name);
    _versionController = TextEditingController(text: plugin.version);
    _baseURLController = TextEditingController(text: plugin.baseURL);
    _searchURLController = TextEditingController(text: plugin.searchURL);
    _searchListController = TextEditingController(text: plugin.searchList);
    _searchNameController = TextEditingController(text: plugin.searchName);
    _searchResultController = TextEditingController(text: plugin.searchResult);
    _chapterRoadsController = TextEditingController(text: plugin.chapterRoads);
    _chapterResultController = TextEditingController(
      text: plugin.chapterResult,
    );
    _userAgentController = TextEditingController(text: plugin.userAgent);
    _refererController = TextEditingController(text: plugin.referer);

    _multiSources = plugin.multiSources;
    _useWebview = plugin.useWebview;
    _usePost = plugin.usePost;
    _useLegacyParser = plugin.useLegacyParser;
    _adBlocker = plugin.adBlocker;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _versionController.dispose();
    _baseURLController.dispose();
    _searchURLController.dispose();
    _searchListController.dispose();
    _searchNameController.dispose();
    _searchResultController.dispose();
    _chapterRoadsController.dispose();
    _chapterResultController.dispose();
    _userAgentController.dispose();
    _refererController.dispose();
    super.dispose();
  }

  Future<void> _savePlugin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final plugin = VideoPlugin(
      api: '1',
      type: 'anime',
      name: _nameController.text.trim(),
      version: _versionController.text.trim(),
      multiSources: _multiSources,
      useWebview: _useWebview,
      useNativePlayer: true,
      usePost: _usePost,
      useLegacyParser: _useLegacyParser,
      adBlocker: _adBlocker,
      userAgent: _userAgentController.text.trim(),
      baseURL: _baseURLController.text.trim(),
      searchURL: _searchURLController.text.trim(),
      searchList: _searchListController.text.trim(),
      searchName: _searchNameController.text.trim(),
      searchResult: _searchResultController.text.trim(),
      chapterRoads: _chapterRoadsController.text.trim(),
      chapterResult: _chapterResultController.text.trim(),
      referer: _refererController.text.trim(),
    );

    await _pluginManager.updatePlugin(plugin);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存成功')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑规则' : '新建规则'),
        actions: [TextButton(onPressed: _savePlugin, child: const Text('保存'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('基本信息', [
              _buildTextField(
                controller: _nameController,
                label: '规则名称',
                hint: '例如: AGE',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入规则名称';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _versionController,
                label: '版本号',
                hint: '例如: 1.0',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入版本号';
                  }
                  return null;
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('网站配置', [
              _buildTextField(
                controller: _baseURLController,
                label: '网站地址',
                hint: 'https://example.com/',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入网站地址';
                  }
                  if (!value.startsWith('http')) {
                    return '请输入有效的URL';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _searchURLController,
                label: '搜索地址',
                hint: 'https://example.com/search?q=@keyword',
                helperText: '使用 @keyword 作为关键词占位符',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入搜索地址';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _userAgentController,
                label: 'User Agent',
                hint: '留空使用默认',
              ),
              _buildTextField(
                controller: _refererController,
                label: 'Referer',
                hint: '留空使用默认',
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('XPath选择器', [
              _buildTextField(
                controller: _searchListController,
                label: '搜索列表',
                hint: '//div[@class="list"]/div',
                helperText: '搜索结果列表的XPath',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入搜索列表XPath';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _searchNameController,
                label: '番剧名称',
                hint: '//h3/a',
                helperText: '番剧名称的XPath',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入番剧名称XPath';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _searchResultController,
                label: '详情链接',
                hint: '//h3/a',
                helperText: '番剧详情页链接的XPath',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入详情链接XPath';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _chapterRoadsController,
                label: '线路列表',
                hint: '//div[@class="play-source"]/div',
                helperText: '播放线路列表的XPath',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入线路列表XPath';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _chapterResultController,
                label: '集数列表',
                hint: '//ul/li/a',
                helperText: '集数列表的XPath',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入集数列表XPath';
                  }
                  return null;
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('高级选项', [
              SwitchListTile(
                title: const Text('多线路'),
                subtitle: const Text('支持多个播放线路'),
                value: _multiSources,
                onChanged: (value) => setState(() => _multiSources = value),
              ),
              SwitchListTile(
                title: const Text('使用WebView'),
                subtitle: const Text('使用WebView解析视频地址'),
                value: _useWebview,
                onChanged: (value) => setState(() => _useWebview = value),
              ),
              SwitchListTile(
                title: const Text('使用POST请求'),
                subtitle: const Text('搜索时使用POST而非GET'),
                value: _usePost,
                onChanged: (value) => setState(() => _usePost = value),
              ),
              SwitchListTile(
                title: const Text('旧版解析器'),
                subtitle: const Text('使用旧版HTML解析器'),
                value: _useLegacyParser,
                onChanged: (value) => setState(() => _useLegacyParser = value),
              ),
              SwitchListTile(
                title: const Text('广告过滤'),
                subtitle: const Text('启用HLS广告过滤'),
                value: _adBlocker,
                onChanged: (value) => setState(() => _adBlocker = value),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
