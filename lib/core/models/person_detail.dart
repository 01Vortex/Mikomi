class PersonDetail {
  final int id;
  final String name;
  final String nameCN;
  final String image;
  final String summary;
  final String info;

  PersonDetail({
    required this.id,
    required this.name,
    required this.nameCN,
    required this.image,
    required this.summary,
    required this.info,
  });

  factory PersonDetail.fromJson(Map<String, dynamic> json) {
    // 解析info字段
    String infoText = '';
    if (json['infobox'] != null) {
      final infobox = json['infobox'] as List<dynamic>;
      for (var item in infobox) {
        final key = item['key'] as String? ?? '';
        final value = item['value'] as dynamic;
        if (key.isNotEmpty) {
          if (value is String) {
            infoText += '$key: $value\n';
          } else if (value is List) {
            final values = value.map((v) => v['v'] ?? v.toString()).join(', ');
            infoText += '$key: $values\n';
          }
        }
      }
    }

    return PersonDetail(
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
