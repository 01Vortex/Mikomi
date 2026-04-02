enum VideoExceptionCode {
  pluginNotFound,
  streamNotFound,
  streamTimeout,
  streamCancelled,
  captchaRequired,
  parseFailed,
  episodeLoadFailed,
  playbackInitializeFailed,
  playbackOpenFailed,
}

class VideoException implements Exception {
  final VideoExceptionCode code;
  final String? detail;

  const VideoException(this.code, {this.detail});

  String get message {
    switch (code) {
      case VideoExceptionCode.pluginNotFound:
        return '视频源插件不存在';
      case VideoExceptionCode.streamNotFound:
        return '未找到可播放视频流';
      case VideoExceptionCode.streamTimeout:
        return '视频解析超时';
      case VideoExceptionCode.streamCancelled:
        return '视频解析已取消';
      case VideoExceptionCode.captchaRequired:
        return '需要通过验证码后继续';
      case VideoExceptionCode.parseFailed:
        return '视频解析失败';
      case VideoExceptionCode.episodeLoadFailed:
        return '剧集加载失败';
      case VideoExceptionCode.playbackInitializeFailed:
        return '播放器初始化失败';
      case VideoExceptionCode.playbackOpenFailed:
        return '视频播放失败';
    }
  }

  @override
  String toString() =>
      detail == null || detail!.isEmpty ? message : '$message: $detail';
}

class VideoStreamTimeoutException extends VideoException {
  final Duration timeout;

  VideoStreamTimeoutException(this.timeout)
    : super(
        VideoExceptionCode.streamTimeout,
        detail: '超时 ${timeout.inSeconds}s',
      );
}

class VideoStreamCancelledException extends VideoException {
  const VideoStreamCancelledException()
    : super(VideoExceptionCode.streamCancelled);
}

class VideoStreamNotFoundException extends VideoException {
  const VideoStreamNotFoundException([String? detail])
    : super(VideoExceptionCode.streamNotFound, detail: detail);
}

class VideoCaptchaRequiredException extends VideoException {
  final String pluginName;
  final String pageUrl;
  final int captchaType;
  final String captchaImageXpath;
  final String captchaInputXpath;
  final String captchaButtonXpath;

  const VideoCaptchaRequiredException({
    required this.pluginName,
    required this.pageUrl,
    required this.captchaType,
    required this.captchaImageXpath,
    required this.captchaInputXpath,
    required this.captchaButtonXpath,
  }) : super(VideoExceptionCode.captchaRequired);
}
