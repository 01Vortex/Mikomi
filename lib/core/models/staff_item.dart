class StaffImages {
  final String large;
  final String medium;
  final String small;
  final String grid;

  StaffImages({
    required this.large,
    required this.medium,
    required this.small,
    required this.grid,
  });

  factory StaffImages.fromJson(Map<String, dynamic> json) {
    return StaffImages(
      large: json['large'] ?? '',
      medium: json['medium'] ?? '',
      small: json['small'] ?? '',
      grid: json['grid'] ?? '',
    );
  }
}

class Staff {
  final int id;
  final String name;
  final String nameCN;
  final StaffImages? images;

  Staff({
    required this.id,
    required this.name,
    required this.nameCN,
    this.images,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameCN: json['nameCN'] ?? '',
      images: json['images'] != null
          ? StaffImages.fromJson(json['images'] as Map<String, dynamic>)
          : null,
    );
  }

  String get displayName => nameCN.isNotEmpty ? nameCN : name;
}

class Position {
  final String cn;

  Position({required this.cn});

  factory Position.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as Map<String, dynamic>?;
    return Position(cn: type?['cn'] ?? '');
  }
}

class StaffItem {
  final Staff staff;
  final List<Position> positions;

  StaffItem({required this.staff, required this.positions});

  factory StaffItem.fromJson(Map<String, dynamic> json) {
    final positionsList =
        (json['positions'] as List?)
            ?.map((item) => Position.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return StaffItem(
      staff: Staff.fromJson(json['staff'] as Map<String, dynamic>),
      positions: positionsList,
    );
  }

  String get positionText =>
      positions.map((p) => p.cn).where((cn) => cn.isNotEmpty).join('、');
}
