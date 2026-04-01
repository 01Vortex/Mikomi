class PersonInfoModel {
  final int id;
  final String name;
  final String nameCN;
  final String image;
  final String summary;
  final String info;

  PersonInfoModel({
    required this.id,
    required this.name,
    required this.nameCN,
    required this.image,
    required this.summary,
    required this.info,
  });

  factory PersonInfoModel.fromJson(Map<String, dynamic> json) {
    var infoText = '';
    if (json['infobox'] != null) {
      final infobox = json['infobox'] as List<dynamic>;
      for (final item in infobox) {
        final key = item['key'] as String? ?? '';
        final value = item['value'];
        if (key.isEmpty) continue;

        if (value is String) {
          infoText += '$key: $value\n';
        } else if (value is List) {
          final values = value.map((v) => v['v'] ?? v.toString()).join(', ');
          infoText += '$key: $values\n';
        }
      }
    }

    return PersonInfoModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameCN: json['name_cn'] as String? ?? '',
      image:
          (json['images'] as Map<String, dynamic>?)?['large'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      info: infoText.trim(),
    );
  }
}
