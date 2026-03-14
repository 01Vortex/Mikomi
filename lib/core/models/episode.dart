class Episode {
  final int number;
  final String? title;
  final String? url;

  Episode({required this.number, this.title, this.url});

  factory Episode.fromRoadData({
    required int index,
    required String identifier,
    required String url,
  }) {
    return Episode(number: index + 1, title: identifier, url: url);
  }
}
