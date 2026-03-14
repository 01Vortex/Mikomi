class CharacterDetail {
  final int id;
  final String name;
  final String nameCN;
  final String info;
  final String summary;
  final String image;

  CharacterDetail({
    required this.id,
    required this.name,
    required this.nameCN,
    required this.info,
    required this.summary,
    required this.image,
  });

  factory CharacterDetail.fromJson(Map<String, dynamic> json) {
    return CharacterDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameCN: json['nameCN'] ?? '',
      info: json['info'] ?? '',
      summary: json['summary'] ?? '',
      image: (json['images'] as Map?)?['large'] ?? '',
    );
  }
}
