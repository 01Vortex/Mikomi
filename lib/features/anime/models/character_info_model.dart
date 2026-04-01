class CharacterInfoModel {
  final int id;
  final String name;
  final String nameCN;
  final String info;
  final String summary;
  final String image;

  CharacterInfoModel({
    required this.id,
    required this.name,
    required this.nameCN,
    required this.info,
    required this.summary,
    required this.image,
  });

  factory CharacterInfoModel.fromJson(Map<String, dynamic> json) {
    return CharacterInfoModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameCN: json['nameCN'] ?? '',
      info: json['info'] ?? '',
      summary: json['summary'] ?? '',
      image: (json['images'] as Map?)?['large'] ?? '',
    );
  }
}
