/// Web 解析传输选项——传递给 [Parsing] 引擎的配置。
class VideoStreamResolveOptions {
  final int captchaType;
  final String captchaImageXpath;
  final String captchaInputXpath;
  final String captchaButtonXpath;

  const VideoStreamResolveOptions({
    this.captchaType = 0,
    this.captchaImageXpath = '',
    this.captchaInputXpath = '',
    this.captchaButtonXpath = '',
  });
}
