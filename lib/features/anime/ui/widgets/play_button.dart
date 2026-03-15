import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mikomi/features/anime/ui/widgets/video_source_selector.dart';
import 'package:mikomi/features/video/ui/pages/video_page.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/core/services/bangumi_episodes_service.dart';
import 'package:mikomi/features/video/data/repositories/video_source_repository.dart';
import 'package:mikomi/features/video/data/services/video_plugin_service.dart';
import 'package:mikomi/shared/widgets/message_dialog.dart';

class PlayButton extends StatefulWidget {
  final VoidCallback? onPlay;
  final List<VideoSource>? videoSources;
  final String? animeTitle;
  final int? bangumiId;

  const PlayButton({
    super.key,
    this.onPlay,
    this.videoSources,
    this.animeTitle,
    this.bangumiId,
  });

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  final BangumiEpisodesService _episodesService = BangumiEpisodesService();
  final VideoSourceRepository _videoSourceRepo = VideoSourceRepository();
  final VideoPluginService _pluginService = VideoPluginService();

  List<Episode>? _episodes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePluginsInBackground();
  }

  void _initializePluginsInBackground() {
    Future.microtask(() async {
      try {
        await _pluginService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('插件初始化超时');
          },
        );
      } catch (e) {
        debugPrint('插件初始化失败: $e');
      }
    });
  }

  Future<void> _loadEpisodesWithVideoSource(String pluginName) async {
    if (widget.animeTitle == null) {
      await _loadBangumiEpisodes();
      return;
    }

    try {
      final videoEpisodes = await _videoSourceRepo
          .searchAndGetEpisodes(widget.animeTitle!, pluginName)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('搜索视频源超时');
              return [];
            },
          );

      List<Episode>? bangumiEpisodes;
      if (widget.bangumiId != null) {
        bangumiEpisodes = await _episodesService
            .getEpisodesBySubjectId(widget.bangumiId!)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('获取Bangumi集数超时');
                return [];
              },
            );
      }

      final mergedEpisodes = <Episode>[];
      for (int i = 0; i < videoEpisodes.length; i++) {
        final videoEp = videoEpisodes[i];
        String? title = videoEp.title;

        if (bangumiEpisodes != null && i < bangumiEpisodes.length) {
          title = bangumiEpisodes[i].title;
        }

        mergedEpisodes.add(
          Episode(number: videoEp.number, title: title, url: videoEp.url),
        );
      }

      if (mounted) {
        setState(() {
          _episodes = mergedEpisodes;
        });
      }
    } catch (e) {
      debugPrint('加载剧集失败: $e');
      if (mounted) {
        setState(() {
          _episodes = [];
        });
      }
    }
  }

  Future<void> _loadBangumiEpisodes() async {
    if (widget.bangumiId == null) return;

    try {
      final episodes = await _episodesService
          .getEpisodesBySubjectId(widget.bangumiId!)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('获取Bangumi集数超时');
              return [];
            },
          );

      if (mounted) {
        setState(() {
          _episodes = episodes;
        });
      }
    } catch (e) {
      debugPrint('加载Bangumi集数失败: $e');
      if (mounted) {
        setState(() {
          _episodes = [];
        });
      }
    }
  }

  void _showVideoSourceSelector(BuildContext context) {
    if (widget.videoSources == null || widget.videoSources!.isEmpty) {
      _loadAndNavigate(null);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoSourceSelector(
        sources: widget.videoSources!,
        animeTitle: widget.animeTitle,
        onSourceSelected: (source) {
          Navigator.pop(context);
          _navigateAndLoadInBackground(source.name);
        },
      ),
    );
  }

  void _navigateAndLoadInBackground(String? pluginName) {
    if (!mounted) {
      debugPrint('组件未挂载，退出');
      return;
    }

    debugPrint('立即跳转到视频页面，插件: $pluginName');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPage(
          title: widget.animeTitle ?? '视频播放',
          videoUrl: '',
          currentEpisode: 1,
          episodes: const [],
          videoSources: widget.videoSources ?? const [],
          pluginName: pluginName,
          animeTitle: widget.animeTitle,
          bangumiId: widget.bangumiId,
        ),
      ),
    );
    widget.onPlay?.call();
  }

  Future<void> _loadAndNavigate(String? pluginName) async {
    if (!mounted) {
      debugPrint('组件未挂载，退出');
      return;
    }

    debugPrint('开始加载剧集，插件: $pluginName');
    setState(() => _isLoading = true);

    try {
      if (pluginName != null) {
        await _loadEpisodesWithVideoSource(pluginName);
      } else {
        await _loadBangumiEpisodes();
      }

      if (!mounted) {
        debugPrint('加载后组件未挂载，退出');
        return;
      }

      setState(() => _isLoading = false);

      debugPrint('加载完成，集数: ${_episodes?.length}');

      if (_episodes == null || _episodes!.isEmpty) {
        debugPrint('未找到剧集数据');
        if (mounted) {
          MessageDialog.warning(context, '未找到剧集数据');
        }
        return;
      }

      if (!mounted) return;

      debugPrint('准备跳转到视频页面');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPage(
            title: widget.animeTitle ?? '视频播放',
            videoUrl: _episodes!.first.url ?? '',
            currentEpisode: 1,
            episodes: _episodes!,
            videoSources: widget.videoSources ?? const [],
          ),
        ),
      );
      widget.onPlay?.call();
    } catch (e, stackTrace) {
      debugPrint('加载失败: $e');
      debugPrint('堆栈: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        MessageDialog.error(context, '加载失败，请重试');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.play_arrow_rounded),
      label: const Text('开始观看'),
      onPressed: _isLoading ? null : () => _showVideoSourceSelector(context),
    );
  }
}
