class CharacterImages {
  final String small;
  final String medium;
  final String grid;
  final String large;

  CharacterImages({
    required this.small,
    required this.medium,
    required this.grid,
    required this.large,
  });

  factory CharacterImages.fromJson(Map<String, dynamic> json) {
    return CharacterImages(
      small: json['small'] ?? '',
      medium: json['medium'] ?? '',
      grid: json['grid'] ?? '',
      large: json['large'] ?? '',
    );
  }
}

class Actor {
  final int id;
  final String name;
  final CharacterImages images;

  Actor({required this.id, required this.name, required this.images});

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      images: CharacterImages.fromJson(json['images'] as Map<String, dynamic>),
    );
  }
}

class CharacterItem {
  final int id;
  final String name;
  final String relation;
  final CharacterImages images;
  final List<Actor> actors;

  CharacterItem({
    required this.id,
    required this.name,
    required this.relation,
    required this.images,
    required this.actors,
  });

  factory CharacterItem.fromJson(Map<String, dynamic> json) {
    final actorsList =
        (json['actors'] as List?)
            ?.map((item) => Actor.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return CharacterItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      relation: json['relation'] ?? '未知',
      images: CharacterImages.fromJson(json['images'] as Map<String, dynamic>),
      actors: actorsList,
    );
  }
}
