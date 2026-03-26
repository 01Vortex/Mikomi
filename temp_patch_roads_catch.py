from pathlib import Path
p=Path(r"d:\Code\Mikomi\lib\features\video\data\video_source_repository.dart")
s=p.read_text(encoding='utf-8')
old="""      return [];
    } catch (e, stackTrace) {
      debugPrint('获取剧集列表失败: $e');
      debugPrint('堆栈: $stackTrace');
      return [];
    }
  }
"""
new="""      return [];
    } on CaptchaRequiredException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('获取剧集列表失败: $e');
      debugPrint('堆栈: $stackTrace');
      return [];
    }
  }
"""
if old not in s:
    raise SystemExit('roads catch snippet not found')
s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')
