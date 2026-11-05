class Icebreaker {
  final String id;
  final String text;
  final bool active;
  final int weight;

  Icebreaker({
    required this.id,
    required this.text,
    this.active = true,
    this.weight = 1,
  });

  factory Icebreaker.fromMap(Map<String, dynamic> map) {
    return Icebreaker(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      active: (map['active'] as bool?) ?? true,
      weight: (map['weight'] as num?)?.toInt() ?? 1,
    );
  }
}
