import 'dart:convert';
import '../core/database/database_helper.dart';
import '../../services/auth_service.dart';
import '../models/habit.dart';

class HabitService {
  final _db = DB.instance;

  // ─── CRUD ────────────────────────────────────────────────────────────────

  Future<List<Habit>> getHabits() async {
    final currentUser = await AuthService().getUsername();

    // Récupération de toutes les clés
    final keys = _db.habitBox.keys;

    final List<Habit> habits = keys
        .map((key) {
          final data = _db.habitBox.get(key);
          final map = Map<String, dynamic>.from(data);
          map['id'] = key;
          return Habit.fromMap(map);
        })
        .where((h) => h.owner == currentUser)
        .toList(); // Désormais, h.owner est reconnu !

    return habits;
  }

  Future<void> addHabit(Habit habit) async {
    final currentUser = await AuthService().getUsername();
    final data = habit.toMap();
    data['owner'] = currentUser;
    await _db.habitBox.add(data);
  }

  Future<void> deleteHabit(int id) async {
    await _db.habitBox.delete(id);
    // Optionnel : supprimer aussi les logs liés à cette habitude
    final keysToDelete = _db.logBox.keys.where((key) {
      final log = _db.logBox.get(key);
      return log['habitId'] == id;
    }).toList();
    await _db.logBox.deleteAll(keysToDelete);
  }

  // ─── GAMIFICATION ────────────────────────────────────────────────────────

  Future<bool> markDone(int habitId) async {
    final today = _dateOnly(DateTime.now());

    // Vérifie si déjà fait (équivalent WHERE habitId=? AND date=?)
    final alreadyDone = _db.logBox.values.any(
      (log) =>
          log['habitId'] == habitId &&
          log['date'] == today &&
          log['status'] == 'done',
    );

    if (alreadyDone) return false;

    // Ajouter le log
    await _db.logBox.add({"habitId": habitId, "date": today, "status": "done"});

    // +10 points sur l'habitude
    final habitMap = Map<String, dynamic>.from(_db.habitBox.get(habitId));
    habitMap['points'] = (habitMap['points'] ?? 0) + 10;
    await _db.habitBox.put(habitId, habitMap);

    return true;
  }

  Future<int> getTotalPoints() async {
    final currentUser = await AuthService().getUsername();
    int total = 0;

    for (var value in _db.habitBox.values) {
      final map = Map<String, dynamic>.from(value);
      // On ne compte les points que si l'owner correspond
      if (map['owner'] == currentUser) {
        total += (map['points'] as int? ?? 0);
      }
    }
    return total;
  }

  // ─── STREAK ──────────────────────────────────────────────────────────────

  Future<int> getStreak(int habitId) async {
    final rows = _db.logBox.values
        .where((log) => log['habitId'] == habitId && log['status'] == 'done')
        .toList();

    final dates = rows.map((r) => DateTime.parse(r["date"] as String)).toList();
    return calculateStreak(dates);
  }

  // Ta fonction calculateStreak reste identique (elle prend déjà une liste de DateTime)
  int calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final unique =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (unique.first.isBefore(today.subtract(const Duration(days: 1))))
      return 0;
    int streak = 1;
    for (int i = 1; i < unique.length; i++) {
      final diff = unique[i - 1].difference(unique[i]).inDays;
      if (diff == 1)
        streak++;
      else
        break;
    }
    return streak;
  }

  Future<String> exportHabitsToJson() async {
    final habits = await getHabits();
    final list = habits
        .map((h) => h.toMap())
        .toList(); // Utilise toMap() ou toJson()
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
