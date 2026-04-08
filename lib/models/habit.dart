class Habit {
  final int? id;
  final String name;
  final String category;
  final String? createdAt;
  int points;
  final String? owner;

  Habit({
    this.id,
    required this.name,
    required this.category,
    this.createdAt,
    this.points = 0,
    this.owner,
  });

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "category": category,
    "createdAt": createdAt ?? DateTime.now().toIso8601String(),
    "points": points,
    'owner': owner,
  };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map["id"],
    name: map["name"],
    category: map["category"],
    createdAt: map["createdAt"],
    points: map["points"] ?? 0,
    owner: map['owner'],
  );

  /// Export JSON
  Map<String, dynamic> toJson() => toMap();
}
