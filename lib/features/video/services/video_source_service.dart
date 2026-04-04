import 'dart:async';

import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/features/video/repository/video_source_repository.dart';

class VideoSourceService {
  final VideoSourceRepository _repository;

  VideoSourceService({VideoSourceRepository? repository})
    : _repository = repository ?? VideoSourceRepository();

  Future<void> initialize() {
    return _repository.initialize();
  }

  List<VideoSource> getAvailableSources() {
    return _repository.plugins
        .map((plugin) => VideoSource(name: plugin.name))
        .toList();
  }

  VideoPlugin? getPluginByName(String name) {
    return _repository.getPluginByName(name);
  }
}
