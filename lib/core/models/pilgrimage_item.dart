class PilgrimageItem {
  final int id;
  final String cn;
  final String title;
  final String city;
  final String cover;
  final String color;
  final List<double> geo;
  final double zoom;
  final int modified;
  final List<LitePoint> litePoints;
  final int pointsLength;
  final int imagesLength;

  PilgrimageItem({
    required this.id,
    required this.cn,
    required this.title,
    required this.city,
    required this.cover,
    required this.color,
    required this.geo,
    required this.zoom,
    required this.modified,
    required this.litePoints,
    required this.pointsLength,
    required this.imagesLength,
  });

  factory PilgrimageItem.fromJson(Map<String, dynamic> json) {
    return PilgrimageItem(
      id: json['id'] ?? 0,
      cn: json['cn'] ?? '',
      title: json['title'] ?? '',
      city: json['city'] ?? '',
      cover: json['cover'] ?? '',
      color: json['color'] ?? '#000000',
      geo: List<double>.from(json['geo'] ?? [0.0, 0.0]),
      zoom: (json['zoom'] ?? 0.0).toDouble(),
      modified: json['modified'] ?? 0,
      litePoints:
          (json['litePoints'] as List?)
              ?.map((e) => LitePoint.fromJson(e))
              .toList() ??
          [],
      pointsLength: json['pointsLength'] ?? 0,
      imagesLength: json['imagesLength'] ?? 0,
    );
  }

  String get mapUrl => 'https://anitabi.cn/map?bangumiId=$id';
}

class LitePoint {
  final String id;
  final String cn;
  final String name;
  final String image;
  final int ep;
  final int s;
  final List<double> geo;

  LitePoint({
    required this.id,
    required this.cn,
    required this.name,
    required this.image,
    required this.ep,
    required this.s,
    required this.geo,
  });

  factory LitePoint.fromJson(Map<String, dynamic> json) {
    return LitePoint(
      id: json['id'] ?? '',
      cn: json['cn'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      ep: json['ep'] ?? 0,
      s: json['s'] ?? 0,
      geo: List<double>.from(json['geo'] ?? [0.0, 0.0]),
    );
  }

  String get displayName => cn.isNotEmpty ? cn : name;

  String get hdImage => image.replaceAll('?plan=h160', '?plan=h360');

  String get fullImage => image.replaceAll('?plan=h160', '');
}
