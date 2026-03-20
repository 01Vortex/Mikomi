import 'package:flutter/material.dart';
import 'package:mikomi/features/video/data/models/video_plugin.dart';
import 'package:mikomi/features/video/data/datasources/video_source_datasource.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/shared/widgets/message_dialog.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:dio/dio.dart';

class PluginTestPage extends StatefulWidget {
  final VideoPlugin plugin;

  const PluginTestPage({super.key, required this.plugin});

  @override
  State<PluginTestPage> createState() => _PluginTestPageState();
}

class _PluginTestPageState extends State<PluginTestPage> {
  final TextEditingController _searchController = TextEditingController();
  final VideoSourceDatasource _datasource = VideoSourceDatasourceImpl();
  final ScrollController _htmlScrollController = ScrollController();
  final ScrollController _chapterScrollController = ScrollController();

  bool _isTesting = false;
  String _searchHtml = '';
  List<SearchResult> _searchResults = [];
  List<Road> _chapters = [];
  final Map<int, String> _itemHtmlMap = {};
  int? _showItemHtmlIdx;

  CancelToken? _cancelToken;

  bool get _hasSearchHtml => _searchHtml.isNotEmpty;
  bool get _hasSearchData => _searchResults.isNotEmpty;
  bool get _hasChapters => _chapters.isNotEmpty;
  bool get _needChapterParse => widget.plugin.chapterRoads.isNotEmpty;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('页面已关闭');
    _searchController.dispose();
    _htmlScrollController.dispose();
    _chapterScrollController.dispose();
    super.dispose();
  }

  void _resetState() {
    _cancelToken?.cancel('重置测试');
    setState(() {
      _searchHtml = '';
      _searchResults = [];
      _chapters = [];
      _itemHtmlMap.clear();
      _showItemHtmlIdx = null;
      _cancelToken = null;
    });
  }

  String _parseItemHtml(int index) {
    if (_itemHtmlMap.containsKey(index)) return _itemHtmlMap[index]!;
    try {
      final document = html_parser.parse(_searchHtml);
      final htmlElement = document.documentElement;
      if (htmlElement == null) return '解析失败：HTML为空';

      final nodes = htmlElement.queryXPath(widget.plugin.searchList).nodes;
      if (index >= nodes.length) return '解析失败：索引超出范围';

      final node = nodes[index].node;
      if (node is html_dom.Element) {
        return _itemHtmlMap[index] = node.outerHtml;
      }
      return '解析失败：节点类型不正确';
    } catch (e) {
      return '解析失败：$e';
    }
  }

  void _toggleItemHtml(int index) {
    if (_showItemHtmlIdx == index) {
      setState(() => _showItemHtmlIdx = null);
      return;
    }
    setState(() => _isTesting = true);
    _parseItemHtml(index);
    setState(() {
      _showItemHtmlIdx = index;
      _isTesting = false;
    });
  }

  Future<void> _startTest() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      if (mounted) {
        MessageDialog.warning(context, '请输入搜索关键词');
      }
      return;
    }

    _resetState();
    setState(() {
      _isTesting = true;
      _cancelToken = CancelToken();
    });

    try {
      // 阶段1: 搜索请求测试
      _searchHtml = await _testSearchRequest(keyword);

      // 检查是否已取消
      if (_cancelToken?.isCancelled ?? true) return;

      // 阶段2: 搜索解析测试
      _searchResults = await _datasource.search(keyword, widget.plugin);

      // 检查是否已取消
      if (_cancelToken?.isCancelled ?? true) return;

      // 阶段3: 章节列表测试
      if (_hasSearchData && _needChapterParse) {
        final firstItem = _searchResults.first;
        if (firstItem.url.isNotEmpty) {
          _chapters = await _datasource.getRoads(firstItem.url, widget.plugin);
        }
      }

      // 测试成功
      if (mounted && _hasSearchData) {
        MessageDialog.success(context, '测试成功，找到 ${_searchResults.length} 个结果');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // 请求被取消，不显示错误
        return;
      }
      if (mounted) {
        MessageDialog.error(context, '测试失败：${e.message ?? "网络请求错误"}');
      }
    } catch (e) {
      if (mounted) {
        MessageDialog.error(context, '测试失败：$e');
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<String> _testSearchRequest(String keyword) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final searchUrl = widget.plugin.searchURL.replaceAll('@keyword', keyword);

    String fullUrl;
    if (searchUrl.startsWith('http')) {
      fullUrl = searchUrl;
    } else if (searchUrl.startsWith('/')) {
      fullUrl = widget.plugin.baseURL + searchUrl;
    } else {
      fullUrl = '${widget.plugin.baseURL}/$searchUrl';
    }

    final response = await dio.get(
      fullUrl,
      cancelToken: _cancelToken,
      options: Options(
        headers: {
          'referer': '${widget.plugin.baseURL}/',
          'user-agent': widget.plugin.userAgent.isNotEmpty
              ? widget.plugin.userAgent
              : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data.toString();
    }
    throw Exception('请求失败：${response.statusCode}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('测试 ${widget.plugin.name}')),
      body: Column(
        children: [
          // 顶部插件信息卡片
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.extension,
                        color: context.colors.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.plugin.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurface,
                            ),
                          ),
                          Text(
                            widget.plugin.baseURL,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 搜索输入区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '输入番剧名称测试',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: context.colors.surfaceContainerHighest,
                    ),
                    enabled: !_isTesting,
                    onSubmitted: (_) => _startTest(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isTesting ? null : _startTest,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('测试'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 测试结果区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTestStageCard(
                    icon: Icons.cloud_download,
                    title: '搜索请求',
                    subtitle: _getSearchSubtitle(),
                    expanded: _hasSearchHtml,
                    child: _buildSearchContent(),
                  ),
                  const SizedBox(height: 12),
                  _buildTestStageCard(
                    icon: Icons.code,
                    title: '搜索解析',
                    subtitle: _getParseSubtitle(),
                    expanded: _hasSearchData,
                    child: _buildParseContent(),
                  ),
                  const SizedBox(height: 12),
                  _buildTestStageCard(
                    icon: Icons.list,
                    title: '章节列表',
                    subtitle: _getChapterSubtitle(),
                    expanded: _hasChapters,
                    child: _buildChapterContent(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestStageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool expanded,
    required Widget child,
  }) {
    final statusColor = _getSubtitleColor(subtitle);
    final isSuccess = statusColor == context.colors.primary;
    final isError = statusColor == context.colors.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant, width: 1),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSuccess
                ? context.colors.primaryContainer
                : isError
                ? context.colors.errorContainer
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSuccess
                ? context.colors.onPrimaryContainer
                : isError
                ? context.colors.onErrorContainer
                : context.colors.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: statusColor),
          ),
        ),
        initiallyExpanded: expanded,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        iconColor: context.colors.primary,
        collapsedIconColor: context.colors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
      ),
    );
  }

  Widget _buildEmpty(String text, {bool isError = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          text,
          style: TextStyle(
            color: isError
                ? context.colors.error
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _getSearchSubtitle() {
    if (_isTesting) return '测试中...';
    if (!_hasSearchHtml) return '未执行测试';
    return 'HTML长度：${_searchHtml.length} 字符';
  }

  Color _getSubtitleColor(String subtitle) {
    if (subtitle.contains('测试中') ||
        subtitle.contains('获取中') ||
        subtitle.contains('解析中')) {
      return context.colors.textSecondary;
    }
    if (subtitle.contains('失败') ||
        subtitle.contains('无可用') ||
        subtitle.contains('无有效')) {
      return context.colors.error;
    }
    return context.colors.primary;
  }

  Widget _buildSearchContent() {
    if (_isTesting) return _buildLoading();
    if (!_hasSearchHtml) return _buildEmpty('点击「测试」按钮开始');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: context.colors.surfaceContainerHighest,
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: context.colors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                '成功获取HTML响应',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.colors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${_searchHtml.length} 字符',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: SingleChildScrollView(
                controller: _htmlScrollController,
                child: SelectableText(
                  _searchHtml,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getParseSubtitle() {
    if (_isTesting && _showItemHtmlIdx == null) return '解析中...';
    if (!_hasSearchHtml) return '未执行解析';
    if (!_hasSearchData) return '未解析到结果';
    return '解析到 ${_searchResults.length} 条结果';
  }

  Widget _buildParseContent() {
    if (_isTesting && _showItemHtmlIdx == null) return _buildLoading();
    if (!_hasSearchHtml) return _buildEmpty('请先完成搜索请求测试');
    if (!_hasSearchData) return _buildEmpty('未解析到搜索结果', isError: true);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (_, i) => _buildSearchItemCard(_searchResults[i], i),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSearchItemCard(SearchResult item, int i) {
    final isShowHtml = _showItemHtmlIdx == i;
    final itemHtml = _itemHtmlMap[i] ?? '加载中...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _isTesting ? null : () => _toggleItemHtml(i),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isShowHtml
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: context.colors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 14,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.url,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isShowHtml)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: context.colors.surface,
                border: Border.all(color: context.colors.outlineVariant),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText(
                  itemHtml,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getChapterSubtitle() {
    if (_isTesting) return '获取中...';
    if (!_hasSearchData) return '无有效搜索结果';
    if (!_needChapterParse) return '无需解析章节';
    if (_chapters.isEmpty && _hasSearchData) return '未获取章节数据';
    return '获取到 ${_chapters.length} 个播放列表';
  }

  Widget _buildChapterContent() {
    if (!_needChapterParse) return _buildEmpty('未填写章节规则');
    if (_isTesting) return _buildLoading();
    if (!_hasSearchData) return _buildEmpty('请先解析到有效结果');
    if (!_hasChapters) return _buildEmpty('无可用章节', isError: true);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        controller: _chapterScrollController,
        itemCount: _chapters.length,
        itemBuilder: (_, i) => _buildChapterCard(_chapters[i], i),
      ),
    );
  }

  Widget _buildChapterCard(Road road, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.playlist_play,
                  color: context.colors.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      road.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '共 ${road.data.length} 集',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: road.identifier.asMap().entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
