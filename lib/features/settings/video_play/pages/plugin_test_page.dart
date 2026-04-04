import 'package:flutter/material.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_test_service.dart';
import 'package:mikomi/features/settings/video_play/service/anti-anti-crawler_test_service.dart';
import 'package:mikomi/shared/theme_extensions.dart';
import 'package:mikomi/shared/message_dialog.dart';
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
  final ScrollController _htmlScrollController = ScrollController();
  final ScrollController _chapterScrollController = ScrollController();

  bool _antiCrawlerEnabled = true;
  String _searchHtml = '';
  List<PluginSearchResult> _searchResults = [];
  List<Road> _chapters = [];
  final Map<int, String> _itemHtmlMap = {};
  int? _showItemHtmlIdx;
  late PluginTestService _service;

  bool get _hasSearchHtml => _searchHtml.isNotEmpty;
  bool get _hasSearchData => _searchResults.isNotEmpty;
  bool get _needChapterParse => widget.plugin.chapterRoads.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _service = PluginTestService(widget.plugin);
  }

  @override
  void dispose() {
    _service.cancel('页面已关闭');
    _searchController.dispose();
    _htmlScrollController.dispose();
    _chapterScrollController.dispose();
    super.dispose();
  }

  void _resetState() {
    _service.cancel('重置测试');
    _service.resetDio();
    _service.cancelToken = CancelToken();
    setState(() {
      _searchHtml = '';
      _searchResults = [];
      _chapters = [];
      _itemHtmlMap.clear();
      _showItemHtmlIdx = null;
    });
  }

  Future<String?> _showCaptchaWebView(String url) async {
    final html = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('验证码验证'),
        content: Text('请在外部完成验证后重试:\n$url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    return html;
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
      if (node is html_dom.Element) return _itemHtmlMap[index] = node.outerHtml;
      return '解析失败：节点类型不正确';
    } catch (e) {
      return '解析失败：$e';
    }
  }

  Future<void> _startTest() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      if (mounted) MessageDialog.warning(context, '请输入搜索关键词');
      return;
    }
    _resetState();
    try {
      final html = await _fetchWithCaptchaRetry(_service.buildSearchUrl(keyword));
      if (html == null) return;
      _searchHtml = html;
      if (mounted) setState(() {});
      if (_service.cancelToken?.isCancelled ?? true) return;

      _searchResults = _service.parseSearchResults(_searchHtml);
      if (mounted) setState(() {});
      if (_service.cancelToken?.isCancelled ?? true) return;

      if (_hasSearchData && _needChapterParse) {
        final firstUrl = _searchResults.first.url;
        if (firstUrl.isNotEmpty) {
          final chapterHtml = await _fetchWithCaptchaRetry(firstUrl);
          if (chapterHtml != null) {
            _chapters = _service.parseChapters(chapterHtml);
            if (mounted) setState(() {});
          }
        }
      }

      if (mounted && _hasSearchData) {
        MessageDialog.success(context, '测试成功，找到 ${_searchResults.length} 个结果');
      } else if (mounted && _hasSearchHtml && !_hasSearchData) {
        MessageDialog.warning(context, '请求成功但未解析到结果，请检查 XPath 规则');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (mounted) MessageDialog.error(context, '测试失败：${e.message ?? "网络请求错误"}');
    } catch (e) {
      if (mounted) MessageDialog.error(context, '测试失败：$e');
    }
  }

  Future<String?> _fetchWithCaptchaRetry(String url) async {
    if (_antiCrawlerEnabled) {
      final aacResult = await AntiAntiCrawlerService.fetch(
        url,
        _service.getDio(),
        cancelToken: _service.cancelToken,
      );
      if (aacResult.success && aacResult.html != null) {
        return aacResult.html;
      }
      if (!aacResult.success && mounted) {
        final verifiedHtml = await _showCaptchaWebView(url);
        return verifiedHtml;
      }
      return null;
    }

    final html = await _service.fetchHtml(url);
    if (html == null) return null;
    if (_service.looksLikeCaptcha(html)) {
      if (!mounted) return null;
      final verifiedHtml = await _showCaptchaWebView(url);
      if (verifiedHtml == null) return null;
      return verifiedHtml;
    }
    return html;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('测试 ${widget.plugin.name}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startTest,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
