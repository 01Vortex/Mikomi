import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// 本地 BT 服务——下载到临时目录，返回 `file://` 路径供 media_kit 播放。
class LibtorrentStreamService {
  bool _initialized = false;
  String? _tempDir;
  final Map<String, _ActiveTorrent> _active = {};

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _tempDir = (await getTemporaryDirectory()).path;
    await LibtorrentFlutter.init(
      defaultSavePath: _tempDir!,
      downloadLimit: 0,
      uploadLimit: 1024 * 1024,
      pollInterval: const Duration(milliseconds: 300),
    );
    _initialized = true;
    debugPrint('LibtorrentStreamService: 临时目录 = $_tempDir');
  }

  /// 下载到临时目录，返回 `file://` URL。
  Future<String?> createStream(String magnetLink) async {
    try {
      await _ensureInit();

      if (_active.containsKey(magnetLink)) {
        return _active[magnetLink]!.fileUrl;
      }

      debugPrint('LibtorrentStreamService: 添加 magnet...');
      final torrentId = LibtorrentFlutter.instance.addMagnet(
        magnetLink,
        _tempDir,
        false, // 正常下载，不限于流模式
      );

      await _waitForMetadata(torrentId, timeout: 30);
      debugPrint('LibtorrentStreamService: 元数据就绪');

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

      // 只下载视频文件
      final priorities = List<int>.filled(files.length, 0);
      priorities[videoIdx] = 7;
      LibtorrentFlutter.instance.setFilePriorities(torrentId, priorities);

      final fileName = files[videoIdx].name;
      // 文件在临时目录下，libtorrent 创建以种子名命名的子目录
      // 文件路径 = tempDir/torrentName/fileName，或者直接 tempDir/fileName
      // 轮询找到实际文件
      final filePath = await _waitForFile(_tempDir!, fileName);

      if (filePath == null) {
        LibtorrentFlutter.instance.removeTorrent(torrentId, deleteFiles: true);
        debugPrint('LibtorrentStreamService: 未找到下载文件');
        return null;
      }

      final fileUrl = Uri.file(filePath).toString();
      _active[magnetLink] = _ActiveTorrent(
        torrentId: torrentId,
        fileUrl: fileUrl,
        filePath: filePath,
      );

      debugPrint(
        'LibtorrentStreamService: 文件就绪 → $fileUrl '
        '($fileName, ${(files[videoIdx].size / 1024 / 1024).toStringAsFixed(0)}MB)',
      );
      return fileUrl;
    } catch (e) {
      debugPrint('LibtorrentStreamService: 创建失败 - $e');
      return null;
    }
  }

  Future<void> stopStream(String magnetLink) async {
    final active = _active.remove(magnetLink);
    if (active != null) {
      try {
        LibtorrentFlutter.instance.removeTorrent(
          active.torrentId,
          deleteFiles: true,
        );
        // 删除临时文件
        File(active.filePath).deleteSync();
      } catch (_) {}
    }
  }

  void dispose() {
    for (final a in _active.values) {
      try {
        LibtorrentFlutter.instance.removeTorrent(a.torrentId, deleteFiles: true);
        File(a.filePath).deleteSync();
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
        if (LibtorrentFlutter.instance.getFiles(torrentId).isNotEmpty) {
          timer.cancel();
          t?.cancel();
          if (!c.isCompleted) c.complete();
        }
      } catch (_) {}
    });
    await c.future;
  }

  /// 轮询等待文件出现并有数据
  Future<String?> _waitForFile(String dir, String fileName) async {
    final c = Completer<String?>();
    Timer? timeout;
    timeout = Timer(const Duration(seconds: 120), () {
      if (!c.isCompleted) c.complete(null);
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        // 递归搜索文件
        final found = _findFile(dir, fileName);
        if (found != null) {
          final file = File(found);
          if (file.existsSync() && file.lengthSync() > 1024 * 1024) {
            // 至少有 1MB 数据
            timer.cancel();
            timeout?.cancel();
            if (!c.isCompleted) c.complete(found);
          }
        }
      } catch (_) {}
    });

    return c.future;
  }

  String? _findFile(String dir, String name) {
    final d = Directory(dir);
    if (!d.existsSync()) return null;
    for (final entity in d.listSync(recursive: true)) {
      if (entity is File) {
        final filePath = entity.path;
        if (filePath.endsWith(name)) return filePath;
      }
    }
    return null;
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
  final String fileUrl;
  final String filePath;
  const _ActiveTorrent({
    required this.torrentId,
    required this.fileUrl,
    required this.filePath,
  });
}
