from pathlib import Path
p=Path(r"d:\Code\Mikomi\lib\features\video\ui\pages\video_page.dart")
s=p.read_text(encoding='utf-8')
old="""    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
    }
"""
new="""    } on CaptchaRequiredException catch (e) {
      debugPrint('加载视频源剧集触发验证码: $e');
      if (mounted) {
        MessageDialog.warning(context, '当前视频源需要验证码验证，请先在视频源站点完成人机验证');
      }
    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
    }
"""
if old not in s:
    raise SystemExit('catch block not found')
s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')
