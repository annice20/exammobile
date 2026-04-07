import 'dart:convert';
import '../core/database/database_helper.dart';
import '../models/habit.dart';

class HabitService {
  // ─── CRUD ────────────────────────────────────────────────────────────────

  Future<List<Habit>> getHabits() async {
    final db = await DB.instance.database;
    final res = await db.query("habits", orderBy: "createdAt DESC");
    return res.map((e) => Habit.fromMap(e)).toList();
  }

  Future<void> addHabit(Habit habit) async {
    final db = await DB.instance.database;
    await db.insert("habits", habit.toMap());
  }

  Future<void> deleteHabit(int id) async {
    final db = await DB.instance.database;
    await db.delete("habits", where: "id=?", whereArgs: [id]);
  }

  // ─── GAMIFICATION ────────────────────────────────────────────────────────

  /// Marque une habitude comme faite AUJOURD'HUI (anti-doublon).
  /// Ajoute +10 points à l'habitude.
  Future<bool> markDone(int habitId) async {
    final db = await DB.instance.database;

    final today = _dateOnly(DateTime.now());

    // Anti-doublon : vérifie si déjà marqué aujourd'hui
    final existing = await db.query(
      "logs",
      where: "habitId=? AND date=? AND status=?",
      whereArgs: [habitId, today, "done"],
    );

    if (existing.isNotEmpty) return false; // déjà fait aujourd'hui

    await db.insert("logs", {
      "habitId": habitId,
      "date": today,
      "status": "done",
    });

    // +10 points
    await db.rawUpdate('UPDATE habits SET points = points + 10 WHERE id = ?', [
      habitId,
    ]);

    return true; // succès
  }

  Future<int> getTotalPoints() async {
    final db = await DB.instance.database;
    final res = await db.rawQuery('SELECT SUM(points) as total FROM habits');
    return (res.first['total'] as int?) ?? 0;
  }

  // ─── STREAK ──────────────────────────────────────────────────────────────

  Future<int> getStreak(int habitId) async {
    final db = await DB.instance.database;
    final rows = await db.query(
      "logs",
      where: "habitId=? AND status=?",
      whereArgs: [habitId, "done"],
      orderBy: "date DESC",
    );

    final dates = rows.map((r) => DateTime.parse(r["date"] as String)).toList();

    return calculateStreak(dates);
  }

  int calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    // Déduplique et trie décroissant
    final unique =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // La série doit commencer aujourd'hui ou hier
    if (unique.first.isBefore(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 1;
    for (int i = 1; i < unique.length; i++) {
      final diff = unique[i - 1].difference(unique[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── EXPORT JSON ─────────────────────────────────────────────────────────

  Future<String> exportHabitsToJson() async {
    final habits = await getHabits();
    final list = habits.map((h) => h.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  // ─── HELPER ──────────────────────────────────────────────────────────────

  String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
