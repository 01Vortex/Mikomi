import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/core/models/video_plugin.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/features/video/services/video_content_service.dart';
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

  bool _isTesting = false;
  bool _antiCrawlerEnabled = true;
  String _searchHtml = '';
  List<SearchResult> _searchResults = [];
  List<Road> _chapters = [];
  final Map<int, String> _itemHtmlMap = {};
  int? _showItemHtmlIdx;
  late PluginTestService _service;

  bool get _hasSearchHtml => _searchHtml.isNotEmpty;
  bool get _hasSearchData => _searchResults.isNotEmpty;
  bool get _hasChapters => _chapters.isNotEmpty;
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
      barrierDismissible: false,
      builder: (ctx) => _CaptchaWebViewDialog(
        url: url,
        baseUrl: widget.plugin.baseURL,
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

  void _toggleItemHtml(int index) {
    if (_showItemHtmlIdx == index) {
      setState(() => _showItemHtmlIdx = null);
      return;
    }
    setState(() => _isTesting = true);
    _parseItemHtml(index);
    setState(() { _showItemHtmlIdx = index; _isTesting = false; });
  }

  Future<void> _startTest() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      if (mounted) MessageDialog.warning(context, '请输入搜索关键词');
      return;
    }
    _resetState();
    setState(() => _isTesting = true);
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
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<String?> _fetchWithCaptchaRetry(String url) async {
    // 反反爬虫模式：先用 AAC 服务突破，再 fallback 到手动验证
    if (_antiCrawlerEnabled) {
      final aacResult = await AntiAntiCrawlerService.fetch(
        url,
        _service.getDio(),
        cancelToken: _service.cancelToken,
      );
      if (aacResult.success && aacResult.html != null) {
        return aacResult.html;
      }
      // AAC 失败后降级到手动 WebView 验证
      if (!aacResult.success && mounted) {
        final verifiedHtml = await _showCaptchaWebView(url);
        return verifiedHtml;
      }
      return null;
    }

    // 普通模式：直接请求，遇验证码弹 WebView
    var html = await _service.fetchHtml(url);
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
                  child: Icon(Icons.extension,
                      color: context.colors.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.plugin.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.onSurface)),
                      Text(widget.plugin.baseURL,
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: const Text('测试'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 反反爬虫开关
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.security, size: 18, color: _antiCrawlerEnabled ? context.colors.primary : context.colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('反反爬虫模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.onSurface)),
                      Text('自动绕过 Cloudflare/验证码拦截，失败时降级到手动验证', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _antiCrawlerEnabled,
                  onChanged: (v) => setState(() => _antiCrawlerEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildStageCard(icon: Icons.cloud_download, title: '搜索请求',
                      subtitle: _getSearchSubtitle(), expanded: _hasSearchHtml, child: _buildSearchContent()),
                  const SizedBox(height: 12),
                  _buildStageCard(icon: Icons.code, title: '搜索解析',
                      subtitle: _getParseSubtitle(), expanded: _hasSearchData, child: _buildParseContent()),
                  const SizedBox(height: 12),
                  _buildStageCard(icon: Icons.list, title: '章节列表',
                      subtitle: _getChapterSubtitle(), expanded: _hasChapters, child: _buildChapterContent()),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStageCard({required IconData icon, required String title, required String subtitle, required bool expanded, required Widget child}) {
    final isError = subtitle.contains('失败') || subtitle.contains('无可用') || subtitle.contains('无有效');
    final isPending = subtitle.contains('中...') || subtitle.contains('未执行') || subtitle.contains('未解析') || subtitle.contains('未获取') || subtitle == '无需解析章节' || subtitle == '无有效搜索结果';
    final isSuccess = !isError && !isPending;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.colors.outlineVariant)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSuccess ? context.colors.primaryContainer : isError ? context.colors.errorContainer : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: isSuccess ? context.colors.onPrimaryContainer : isError ? context.colors.onErrorContainer : context.colors.onSurfaceVariant),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: TextStyle(fontSize: 12, color: isError ? context.colors.error : isSuccess ? context.colors.primary : context.colors.textSecondary))),
        initiallyExpanded: expanded,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }

  String _getSearchSubtitle() {
    if (_isTesting && !_hasSearchHtml) return '测试中...';
    if (!_hasSearchHtml) return '未执行测试';
    return 'HTML长度：${_searchHtml.length} 字符';
  }

  String _getParseSubtitle() {
    if (_isTesting && !_hasSearchData) return '解析中...';
    if (!_hasSearchHtml) return '未执行解析';
    if (!_hasSearchData) return '未解析到结果';
    return '解析到 ${_searchResults.length} 条结果';
  }

  String _getChapterSubtitle() {
    if (!_needChapterParse) return '无需解析章节';
    if (_isTesting && _hasSearchData && !_hasChapters) return '获取中...';
    if (!_hasSearchData) return '无有效搜索结果';
    if (!_hasChapters) return '未获取章节数据';
    return '获取到 ${_chapters.length} 个播放列表';
  }

  Widget _buildLoading() => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary))));
  Widget _buildEmpty(String text, {bool isError = false}) => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(text, style: TextStyle(color: isError ? context.colors.error : context.colors.textSecondary))));

  Widget _buildSearchContent() {
    if (_isTesting && !_hasSearchHtml) return _buildLoading();
    if (!_hasSearchHtml) return _buildEmpty('点击「测试」按钮开始');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.colors.surfaceContainerHighest),
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.check_circle, color: context.colors.primary, size: 16),
            const SizedBox(width: 8),
            Text('成功获取HTML响应', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.primary)),
            const Spacer(),
            Text('${_searchHtml.length} 字符', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Expanded(child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: context.colors.outlineVariant)),
            child: SingleChildScrollView(controller: _htmlScrollController, child: SelectableText(_searchHtml, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: context.colors.onSurface))),
          )),
        ],
      ),
    );
  }

  Widget _buildParseContent() {
    if (_isTesting && !_hasSearchData) return _buildLoading();
    if (!_hasSearchHtml) return _buildEmpty('请先完成搜索请求测试');
    if (!_hasSearchData) return _buildEmpty('未解析到搜索结果', isError: true);
    return Column(children: [ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _searchResults.length, itemBuilder: (_, i) => _buildSearchItemCard(_searchResults[i], i)), const SizedBox(height: 8)]);
  }

  Widget _buildSearchItemCard(SearchResult item, int i) {
    final isShowHtml = _showItemHtmlIdx == i;
    final itemHtml = _itemHtmlMap[i] ?? '加载中...';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: context.colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.outlineVariant)),
      child: Column(children: [
        InkWell(
          onTap: _isTesting ? null : () => _toggleItemHtml(i),
          borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.onPrimaryContainer)))),
              const SizedBox(width: 12),
              Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis)),
              Icon(isShowHtml ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: context.colors.primary, size: 20),
            ]),
            const SizedBox(height: 8),
            Row(children: [Icon(Icons.link, size: 14, color: context.colors.textSecondary), const SizedBox(width: 4), Expanded(child: Text(item.url, style: TextStyle(fontSize: 12, color: context.colors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis))]),
          ])),
        ),
        if (isShowHtml) Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12), padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.colors.surface, border: Border.all(color: context.colors.outlineVariant)),
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(child: SelectableText(itemHtml, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: context.colors.onSurface))),
        ),
      ]),
    );
  }

  Widget _buildChapterContent() {
    if (!_needChapterParse) return _buildEmpty('未填写章节规则');
    if (_isTesting && !_hasChapters) return _buildLoading();
    if (!_hasSearchData) return _buildEmpty('请先解析到有效结果');
    if (!_hasChapters) return _buildEmpty('无可用章节', isError: true);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(controller: _chapterScrollController, itemCount: _chapters.length, itemBuilder: (_, i) => _buildChapterCard(_chapters[i])),
    );
  }

  Widget _buildChapterCard(Road road) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.playlist_play, color: context.colors.onPrimaryContainer, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(road.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Text('共 ${road.data.length} 集', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.colors.outlineVariant)),
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(child: Wrap(spacing: 8, runSpacing: 8, children: road.identifier.map((name) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: context.colors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
            child: Text(name, style: TextStyle(fontSize: 12, color: context.colors.onSecondaryContainer)),
          )).toList())),
        ),
      ]),
    );
  }
}

// ── 验证码 WebView 对话框 ────────────────────────────────────────────────────

class _CaptchaWebViewDialog extends StatefulWidget {
  final String url;
  final String baseUrl;
  const _CaptchaWebViewDialog({required this.url, required this.baseUrl});
  @override
  State<_CaptchaWebViewDialog> createState() => _CaptchaWebViewDialogState();
}

class _CaptchaWebViewDialogState extends State<_CaptchaWebViewDialog> {
  bool _isLoading = true;
  InAppWebViewController? _webCtrl;
  String _pageTitle = '完成验证后点击「继续」';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.security_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_pageTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(null),
                    tooltip: '取消',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    initialSettings: InAppWebViewSettings(
                      userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
                      javaScriptEnabled: true,
                      cacheEnabled: true,
                    ),
                    onWebViewCreated: (ctrl) => _webCtrl = ctrl,
                    onLoadStart: (ctrl, url) => setState(() => _isLoading = true),
                    onLoadStop: (_, url) => setState(() => _isLoading = false),
                    onTitleChanged: (_, title) {
                      if (title != null && title.isNotEmpty) {
                        setState(() => _pageTitle = title);
                      }
                    },
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _webCtrl?.reload(),
                    child: const Text('刷新'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      // 直接取 WebView 当前页 HTML，省去 Dio 重新请求
                      final html = await _webCtrl?.getHtml();
                      if (context.mounted) Navigator.of(context).pop(html);
                    },
                    child: const Text('继续测试'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
