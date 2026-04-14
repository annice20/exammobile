import 'dart:convert';
import '../services/auth_service.dart';
import '../core/database/database_helper.dart';
import '../models/habit.dart';

class HabitService {
  final _db = DB.instance;

  // ─── CRUD ────────────────────────────────────────────────────────────────

  Future<List<Habit>> getHabits() async {
    final currentUser = await AuthService().getUsername();
    final keys = _db.habitBox.keys;
    final habits = keys.map((key) {
      final data = _db.habitBox.get(key);
      final map = Map<String, dynamic>.from(data);
      map['id'] = key;
      return Habit.fromMap(map);
    }).where((habit) => habit.owner == currentUser).toList();
    return habits;
  }

  Future<void> addHabit(Habit habit) async {
    final currentUser = await AuthService().getUsername();
    final data = habit.toMap();
    data['owner'] = currentUser;
    await _db.habitBox.add(data);
  }

  Future<void> updateHabit(Habit habit) async {
    final existing = _db.habitBox.get(habit.id);
    if (existing == null) return;
    final map = Map<String, dynamic>.from(existing);
    map['name'] = habit.name;
    map['description'] = habit.description;
    map['category'] = habit.category;
    map['frequency'] = habit.frequency;
    await _db.habitBox.put(habit.id, map);
  }

  Future<void> deleteHabit(int id) async {
    await _db.habitBox.delete(id);
    final keysToDelete = _db.logBox.keys.where((key) {
      final log = _db.logBox.get(key);
      return log['habitId'] == id;
    }).toList();
    await _db.logBox.deleteAll(keysToDelete);
  }

  // ─── SUIVI QUOTIDIEN ─────────────────────────────────────────────────────

  Future<bool> markDone(int habitId) async {
    final today = _dateOnly(DateTime.now());
    final alreadyDone = _db.logBox.values.any(
      (log) =>
          log['habitId'] == habitId &&
          log['date'] == today &&
          log['status'] == 'done',
    );
    if (alreadyDone) return false;

    await _db.logBox.add({
      'habitId': habitId,
      'date': today,
      'status': 'done',
      'createdAt': DateTime.now().toIso8601String(),
    });

    final habitMap = Map<String, dynamic>.from(_db.habitBox.get(habitId));
    habitMap['points'] = (habitMap['points'] ?? 0) + 10;
    await _db.habitBox.put(habitId, habitMap);
    return true;
  }

  Future<bool> markHabit(int habitId, String status) async {
    final today = _dateOnly(DateTime.now());
    final existing = _db.logBox.values.any(
      (log) => log['habitId'] == habitId && log['date'] == today,
    );
    if (existing) return false;
    await _db.logBox.add({
      'habitId': habitId,
      'date': today,
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<String?> getStatusToday(int habitId) async {
    final today = _dateOnly(DateTime.now());
    final log = _db.logBox.values.firstWhere(
      (log) => log['habitId'] == habitId && log['date'] == today,
      orElse: () => null,
    );
    return log?['status'] as String?;
  }

  // ─── LOGS / CALENDRIER ───────────────────────────────────────────────────

  Future<Map<String, String>> getLogsForHabit(int habitId) async {
    final Map<String, String> result = {};
    for (final log in _db.logBox.values) {
      if (log['habitId'] == habitId) {
        result[log['date'] as String] = log['status'] as String;
      }
    }
    return result;
  }

  // ─── STREAK ──────────────────────────────────────────────────────────────

  Future<int> getStreak(int habitId) async {
    final rows = _db.logBox.values
        .where((log) =>
            log['habitId'] == habitId && log['status'] == 'done')
        .toList();
    final dates = rows
        .map((row) => DateTime.parse(row['date'] as String))
        .toList();
    return calculateStreak(dates);
  }

  Future<int> getLongestStreak(int habitId) async {
    final dates = _db.logBox.values
        .where((log) =>
            log['habitId'] == habitId && log['status'] == 'done')
        .map((log) => DateTime.parse(log['date'] as String))
        .toList()
      ..sort();
    if (dates.isEmpty) return 0;
    int maxS = 1, cur = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        cur++;
        if (cur > maxS) maxS = cur;
      } else {
        cur = 1;
      }
    }
    return maxS;
  }

  int calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final unique =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (unique.first.isBefore(today.subtract(const Duration(days: 1)))) {
      return 0;
    }
    var streak = 1;
    for (var i = 1; i < unique.length; i++) {
      if (unique[i - 1].difference(unique[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── TAUX DE RÉUSSITE ────────────────────────────────────────────────────

  Future<double> getMonthlyRate(int habitId) async {
    final now = DateTime.now();
    final monthStart = _dateOnly(DateTime(now.year, now.month, 1));
    final todayStr = _dateOnly(now);
    final done = _db.logBox.values.where((log) =>
        log['habitId'] == habitId &&
        log['status'] == 'done' &&
        (log['date'] as String).compareTo(monthStart) >= 0 &&
        (log['date'] as String).compareTo(todayStr) <= 0).length;
    return now.day > 0 ? (done / now.day * 100) : 0;
  }

  Future<double> getWeeklyRate(int habitId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startStr = _dateOnly(weekStart);
    final todayStr = _dateOnly(now);
    final done = _db.logBox.values.where((log) =>
        log['habitId'] == habitId &&
        log['status'] == 'done' &&
        (log['date'] as String).compareTo(startStr) >= 0 &&
        (log['date'] as String).compareTo(todayStr) <= 0).length;
    return now.weekday > 0 ? (done / now.weekday * 100) : 0;
  }

  // ─── STATS DASHBOARD ─────────────────────────────────────────────────────

  Future<int> getHabitsDoneToday() async {
    final today = _dateOnly(DateTime.now());
    final currentUser = await AuthService().getUsername();
    final userHabitIds = _db.habitBox.keys.where((key) {
      final data = _db.habitBox.get(key);
      return data != null && data['owner'] == currentUser;
    }).toSet();
    final doneIds = _db.logBox.values
        .where((log) =>
            log['date'] == today &&
            log['status'] == 'done' &&
            userHabitIds.contains(log['habitId']))
        .map((log) => log['habitId'])
        .toSet();
    return doneIds.length;
  }

  Future<int> getTotalPoints() async {
    final currentUser = await AuthService().getUsername();
    var total = 0;
    for (final value in _db.habitBox.values) {
      final map = Map<String, dynamic>.from(value);
      if (map['owner'] == currentUser) {
        total += (map['points'] as int? ?? 0);
      }
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = _dateOnly(day);
      final count = _db.logBox.values
          .where((log) =>
              log['date'] == dateStr && log['status'] == 'done')
          .length;
      result.add({
        "date": dateStr,
        "count": count,
        "label": _dayLabel(day.weekday),
      });
    }
    return result;
  }

  String _dayLabel(int w) =>
      ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"][w - 1];

  // ─── RESET ───────────────────────────────────────────────────────────────

  Future<void> resetAllStats() async {
    final currentUser = await AuthService().getUsername();
    final userHabitIds = <dynamic>{};
    for (final key in _db.habitBox.keys) {
      final data = _db.habitBox.get(key);
      if (data == null) continue;
      final habitMap = Map<String, dynamic>.from(data);
      if (habitMap['owner'] != currentUser) continue;
      userHabitIds.add(key);
      habitMap['points'] = 0;
      await _db.habitBox.put(key, habitMap);
    }
    if (userHabitIds.isEmpty) return;
    final logKeysToDelete = _db.logBox.keys.where((key) {
      final log = _db.logBox.get(key);
      return log != null && userHabitIds.contains(log['habitId']);
    }).toList();
    if (logKeysToDelete.isNotEmpty) {
      await _db.logBox.deleteAll(logKeysToDelete);
    }
  }

  // ─── EXPORT JSON ─────────────────────────────────────────────────────────

  Future<String> exportHabitsToJson() async {
    final habits = await getHabits();
    final list = habits.map((habit) => habit.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  // ─── HELPER ──────────────────────────────────────────────────────────────

  String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}