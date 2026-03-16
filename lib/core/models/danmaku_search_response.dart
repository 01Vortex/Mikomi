class DanmakuAnime {
  final int animeId;
  final String animeTitle;
  final String type;
  final String typeDescription;
  final String imageUrl;
  final DateTime startDate;
  final int episodeCount;
  final double rating;
  final bool isFavorited;

  DanmakuAnime({
    required this.animeId,
    required this.animeTitle,
    required this.type,
    required this.typeDescription,
    required this.imageUrl,
    required this.startDate,
    required this.episodeCount,
    required this.rating,
    required this.isFavorited,
  });

  factory DanmakuAnime.fromJson(Map<String, dynamic> json) {
    return DanmakuAnime(
      animeId: json['animeId'],
      animeTitle: json['animeTitle'],
      type: json['type'],
      typeDescription: json['typeDescription'],
      imageUrl: json['imageUrl'],
      startDate: DateTime.parse(json['startDate']),
      episodeCount: json['episodeCount'],
      rating: json['rating'].toDouble(),
      isFavorited: json['isFavorited'],
    );
  }
}

class DanmakuSearchResponse {
  final List<DanmakuAnime> animes;
  final int errorCode;
  final bool success;
  final String errorMessage;

  DanmakuSearchResponse({
    required this.animes,
    required this.errorCode,
    required this.success,
    required this.errorMessage,
  });

  factory DanmakuSearchResponse.fromJson(Map<String, dynamic> json) {
    var list = json['animes'] as List;
    List<DanmakuAnime> animeList = list
        .map((i) => DanmakuAnime.fromJson(i))
        .toList();

    return DanmakuSearchResponse(
      animes: animeList,
      errorCode: json['errorCode'],
      success: json['success'],
      errorMessage: json['errorMessage'],
    );
  }
}
