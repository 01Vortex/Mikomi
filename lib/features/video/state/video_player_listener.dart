import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';

String formatVideoDuration(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  return '${twoDigits(minutes)}:${twoDigits(seconds)}';
}

class VideoPlayerSnapshot {
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;

  const VideoPlayerSnapshot({
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.playbackSpeed,
  });

  factory VideoPlayerSnapshot.initial() {
    return const VideoPlayerSnapshot(
      isPlaying: false,
      isBuffering: false,
      position: Duration.zero,
      duration: Duration.zero,
      playbackSpeed: 1.0,
    );
  }

  factory VideoPlayerSnapshot.fromPlayer(Player player) {
    return VideoPlayerSnapshot(
      isPlaying: player.state.playing,
      isBuffering: player.state.buffering,
      position: player.state.position,
      duration: player.state.duration,
      playbackSpeed: player.state.rate,
    );
  }

  VideoPlayerSnapshot copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
  }) {
    return VideoPlayerSnapshot(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class VideoPlayerListenerController {
  final PlaySettingsService _playSettingsService;
  final void Function(VideoPlayerSnapshot snapshot)? onSnapshotChanged;
  final ValueChanged<Duration>? onPositionChanged;
  final ValueChanged<Duration>? onDurationChanged;
  final ValueChanged<bool>? onPlayingChanged;
  final ValueChanged<bool>? onBufferingChanged;
  final ValueChanged<double>? onPlaybackSpeedChanged;
  final VoidCallback? onAutoPlayNext;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _rateSubscription;
  StreamSubscription<bool>? _completedSubscription;
  VideoPlayerSnapshot _snapshot = VideoPlayerSnapshot.initial();

  VideoPlayerListenerController({
    PlaySettingsService? playSettingsService,
    this.onSnapshotChanged,
    this.onPositionChanged,
    this.onDurationChanged,
    this.onPlayingChanged,
    this.onBufferingChanged,
    this.onPlaybackSpeedChanged,
    this.onAutoPlayNext,
  }) : _playSettingsService = playSettingsService ?? PlaySettingsService();

  VideoPlayerSnapshot get snapshot => _snapshot;

  void bind(Player? player, {bool hasNextEpisode = false}) {
    cancel();
    if (player == null) {
      _snapshot = VideoPlayerSnapshot.initial();
      onSnapshotChanged?.call(_snapshot);
      return;
    }

    _snapshot = VideoPlayerSnapshot.fromPlayer(player);
    onSnapshotChanged?.call(_snapshot);

    _playingSubscription = player.stream.playing.listen((isPlaying) {
      _snapshot = _snapshot.copyWith(isPlaying: isPlaying);
      onPlayingChanged?.call(isPlaying);
      onSnapshotChanged?.call(_snapshot);
    });

    _bufferingSubscription = player.stream.buffering.listen((isBuffering) {
      _snapshot = _snapshot.copyWith(isBuffering: isBuffering);
      onBufferingChanged?.call(isBuffering);
      onSnapshotChanged?.call(_snapshot);
    });

    _positionSubscription = player.stream.position.listen((position) {
      _snapshot = _snapshot.copyWith(position: position);
      onPositionChanged?.call(position);
      onSnapshotChanged?.call(_snapshot);
    });

    _durationSubscription = player.stream.duration.listen((duration) {
      _snapshot = _snapshot.copyWith(duration: duration);
      onDurationChanged?.call(duration);
      onSnapshotChanged?.call(_snapshot);
    });

    _rateSubscription = player.stream.rate.listen((playbackSpeed) {
      _snapshot = _snapshot.copyWith(playbackSpeed: playbackSpeed);
      onPlaybackSpeedChanged?.call(playbackSpeed);
      onSnapshotChanged?.call(_snapshot);
    });

    _completedSubscription = player.stream.completed.listen((completed) async {
      if (!completed || onAutoPlayNext == null || !hasNextEpisode) {
        return;
      }

      final position = player.state.position.inSeconds;
      final duration = player.state.duration.inSeconds;
      if (duration <= 0 || position < duration - 3) {
        return;
      }

      final autoPlayNext = await _playSettingsService.getAutoPlayNext();
      if (autoPlayNext) {
        onAutoPlayNext?.call();
      }
    });
  }

  void cancel() {
    _playingSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _rateSubscription?.cancel();
    _completedSubscription?.cancel();
    _playingSubscription = null;
    _bufferingSubscription = null;
    _positionSubscription = null;
    _durationSubscription = null;
    _rateSubscription = null;
    _completedSubscription = null;
  }

  void dispose() {
    cancel();
  }
}
