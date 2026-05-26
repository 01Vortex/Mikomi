import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// 本地 BT 流服务——使用 libtorrent 在设备上直接下载并流式播放。
///
/// 优化点：
/// - DHT 引导节点加速 peer 发现
/// - 不限速下载
/// - `preloadStream` 预加载头部 16MB 快速起播
/// - 元数据缓存避免重复等待
class LibtorrentStreamService {
  bool _initialized = false;
  final Map<String, _ActiveTorrent> _active = {};

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    await LibtorrentFlutter.init(
      defaultSavePath: dir.path,
      downloadLimit: 0, // 不限速
      uploadLimit: 1024 * 1024, // 上传限 1MB/s
      pollInterval: const Duration(milliseconds: 300), // 更快轮询
    );
    _initialized = true;
    debugPrint('LibtorrentStreamService: 初始化完成');
  }

  /// 创建本地流，返回可供 media_kit 播放的 URL。
  Future<String?> createStream(String magnetLink) async {
    try {
      await _ensureInit();

      if (_active.containsKey(magnetLink)) {
        return _active[magnetLink]!.streamInfo.url;
      }

      debugPrint('LibtorrentStreamService: 添加 magnet...');
      final torrentId = LibtorrentFlutter.instance.addMagnet(
        magnetLink,
        null,
        true, // streamOnly
      );

      // 等待元数据（最多 30 秒）
      final start = DateTime.now();
      await _waitForMetadata(torrentId, timeout: 30);
      debugPrint('LibtorrentStreamService: 元数据就绪 (${DateTime.now().difference(start).inSeconds}s)');

      final files = LibtorrentFlutter.instance.getFiles(torrentId);
      if (files.isEmpty) {
        LibtorrentFlutter.instance.removeTorrent(torrentId, deleteFiles: true);
        return null;
      }

      final videoIdx = _pickVideoIndex(files);
      if (videoIdx < 0) {
        LibtorrentFlutter.instance.removeTorrent(torrentId, deleteFiles: true);
        return null;
      }

      // 只下载视频文件，优先级最高
      final priorities = List<int>.filled(files.length, 0);
      priorities[videoIdx] = 7;
      LibtorrentFlutter.instance.setFilePriorities(torrentId, priorities);

      // 启动流
      final streamInfo = LibtorrentFlutter.instance.startStream(
        torrentId,
        fileIndex: videoIdx,
        maxCacheBytes: 64 * 1024 * 1024,
      );

      // 缓存设置（需要 streamInfo.id）
      LibtorrentFlutter.instance.setCacheSettings(
        streamInfo.id,
        capacity: 64 * 1024 * 1024,
        readAheadPct: 30,
        connectionsLimit: 100,
      );

      // 预加载头部 16MB → 快速起播
      try {
        LibtorrentFlutter.instance.preloadStream(streamInfo.id);
        debugPrint('LibtorrentStreamService: 预加载头部 16MB...');
      } catch (_) {}

      _active[magnetLink] = _ActiveTorrent(
        torrentId: torrentId,
        streamInfo: streamInfo,
      );

      debugPrint(
        'LibtorrentStreamService: 流就绪 → ${streamInfo.url} '
        '(${files[videoIdx].name}, ${(files[videoIdx].size / 1024 / 1024).toStringAsFixed(0)}MB)',
      );
      return streamInfo.url;
    } catch (e) {
      debugPrint('LibtorrentStreamService: 创建流失败 - $e');
      return null;
    }
  }

  Future<void> stopStream(String magnetLink) async {
    final active = _active.remove(magnetLink);
    if (active != null) {
      try {
        LibtorrentFlutter.instance.stopStream(active.streamInfo.id);
        LibtorrentFlutter.instance.removeTorrent(active.torrentId, deleteFiles: true);
      } catch (_) {}
    }
  }

  void dispose() {
    for (final a in _active.values) {
      try {
        LibtorrentFlutter.instance.stopStream(a.streamInfo.id);
        LibtorrentFlutter.instance.removeTorrent(a.torrentId, deleteFiles: true);
      } catch (_) {}
    }
    _active.clear();
    if (_initialized) {
      try {
        LibtorrentFlutter.instance.dispose();
      } catch (_) {}
      _initialized = false;
    }
  }

  // ── 内部 ──

  Future<void> _waitForMetadata(int torrentId, {int timeout = 30}) async {
    final c = Completer<void>();
    Timer? t;

    t = Timer(Duration(seconds: timeout), () {
      if (!c.isCompleted) c.completeError(TimeoutException('元数据超时'));
    });

    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      try {
        final files = LibtorrentFlutter.instance.getFiles(torrentId);
        if (files.isNotEmpty) {
          timer.cancel();
          t?.cancel();
          if (!c.isCompleted) c.complete();
        }
      } catch (_) {}
    });

    await c.future;
  }

  int _pickVideoIndex(List<FileInfo> files) {
    const exts = {'.mp4', '.mkv', '.avi', '.mov', '.webm', '.flv', '.m4v'};
    int bestIdx = -1;
    int bestSize = 0;

    for (int i = 0; i < files.length; i++) {
      if (exts.any((e) => files[i].name.toLowerCase().endsWith(e)) &&
          files[i].size > bestSize) {
        bestSize = files[i].size;
        bestIdx = i;
      }
    }

    if (bestIdx < 0 && files.isNotEmpty) {
      for (int i = 0; i < files.length; i++) {
        if (files[i].size > bestSize) {
          bestSize = files[i].size;
          bestIdx = i;
        }
      }
    }
    return bestIdx;
  }
}

class _ActiveTorrent {
  final int torrentId;
  final StreamInfo streamInfo;
  const _ActiveTorrent({required this.torrentId, required this.streamInfo});
}
