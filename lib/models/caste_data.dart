class CasteData {
  final String id;
  final String name;
  final String religion;

  CasteData({required this.id, required this.name, required this.religion});

  factory CasteData.fromJson(Map<String, dynamic> json) {
    return CasteData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      religion: json['religion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'religion': religion};
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CasteData && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
