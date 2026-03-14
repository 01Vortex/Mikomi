class Road {
  final String name;
  final List<String> data;
  final List<String> identifier;

  Road({required this.name, required this.data, required this.identifier});

  factory Road.fromJson(Map<String, dynamic> json) {
    return Road(
      name: json['name'] as String,
      data: List<String>.from(json['data'] as List),
      identifier: List<String>.from(json['identifier'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'data': data, 'identifier': identifier};
  }
}
