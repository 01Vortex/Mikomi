from pathlib import Path
p=Path(r"d:\Code\Mikomi\lib\features\video\data\video_source_repository.dart")
s=p.read_text(encoding='utf-8')
old="""      return [];
    } catch (e) {
      debugPrint('搜索失败: $e');
      return [];
    }
  }
"""
new="""      return [];
    } on CaptchaRequiredException {
      rethrow;
    } catch (e) {
      debugPrint('搜索失败: $e');
      return [];
    }
  }
"""
if old not in s:
    raise SystemExit('search catch snippet not found')
s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')
