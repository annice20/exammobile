class Habit {
  final int? id;
  final String name;
  final String description;
  final String category;
  final String frequency;
  final String? createdAt;
  int points;
  final String? owner;

  Habit({
    this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.frequency = 'Quotidienne',
    this.createdAt,
    this.points = 0,
    this.owner,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "description": description,
        "category": category,
        "frequency": frequency,
        "createdAt": createdAt ?? DateTime.now().toIso8601String(),
        "points": points,
        'owner': owner,
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map["id"],
        name: map["name"],
        description: map["description"] ?? '',
        category: map["category"] ?? '',
        frequency: map["frequency"] ?? 'Quotidienne',
        createdAt: map["createdAt"],
        points: map["points"] ?? 0,
        owner: map['owner'],
      );

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? frequency,
    String? createdAt,
    int? points,
    String? owner,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        frequency: frequency ?? this.frequency,
        createdAt: createdAt ?? this.createdAt,
        points: points ?? this.points,
        owner: owner ?? this.owner,
      );

  Map<String, dynamic> toJson() => toMap();
}