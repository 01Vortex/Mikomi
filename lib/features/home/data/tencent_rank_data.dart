import 'package:html/parser.dart' as html_parser;
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/home/data/rank_record.dart';

class TencentRankData {
  final DioClient _dioClient = DioClient();

  Future<List<RankRecord>> getChineseAnimeRank({int limit = 30}) async {
    try {
      final response = await _dioClient.get(
        'https://v.qq.com/x/bu/pagesheet/list',
        queryParameters: {
          'append': 1,
          'channel': 'cartoon',
          'iarea': 1,
          'listpage': 2,
          'offset': 0,
          'pagesize': limit,
        },
      );

      final html = response.data.toString();
      final document = html_parser.parse(html);
      final cards = document.querySelectorAll('.list_item');

      final result = <RankRecord>[];
      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final titleAnchor = card.querySelector('.figure_title');
        final coverAnchor = card.querySelector('a.figure');
        final image = card.querySelector('img.figure_pic');
        final desc = card.querySelector('.figure_desc');

        final title =
            titleAnchor?.attributes['title']?.trim() ??
            titleAnchor?.text.trim() ??
            coverAnchor?.attributes['title']?.trim() ??
            '';
        final cover = image?.attributes['src']?.trim() ?? '';
        final href =
            coverAnchor?.attributes['href']?.trim() ??
            titleAnchor?.attributes['href']?.trim() ??
            '';
        final summary = desc?.attributes['title']?.trim() ?? desc?.text.trim() ?? '';

        if (title.isEmpty || cover.isEmpty) {
          continue;
        }

        final id = _stableId(href.isEmpty ? '$title-$i' : href);
        final item = Anime(
          id: id,
          name: title,
          nameCn: title,
          summary: summary,
          airDate: '',
          images: {
            'large': cover,
            'common': cover,
            'medium': cover,
            'small': cover,
            'grid': cover,
          },
          ratingScore: 0,
          ratingCount: 0,
          rank: i + 1,
          tags: [BangumiTag(name: '国漫', count: 0)],
          info: '',
        );

        final metric = cards.length - i;
        result.add(RankRecord(item: item, metric: metric));
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  int _stableId(String text) {
    var hash = 0;
    for (final codeUnit in text.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
