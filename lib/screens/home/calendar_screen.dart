import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _service = HabitService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Habit> _habits = [];
  Map<String, Map<String, String>> _allLogs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final habits = await _service.getHabits();
    final Map<String, Map<String, String>> allLogs = {};
    for (final h in habits) {
      allLogs[h.id.toString()] = await _service.getLogsForHabit(h.id!);
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _allLogs = allLogs;
      _loading = false;
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Statut global d'un jour (toutes les habitudes confondues)
  String? _globalStatus(DateTime day) {
    final key = _dateKey(day);
    final statuses = <String>[];
    for (final logs in _allLogs.values) {
      if (logs.containsKey(key)) statuses.add(logs[key]!);
    }
    if (statuses.isEmpty) return null;
    if (statuses.any((s) => s == 'done')) return 'done';
    if (statuses.any((s) => s == 'postponed')) return 'postponed';
    return 'skipped';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'done': return Colors.green;
      case 'postponed': return Colors.orange;
      case 'skipped': return Colors.red;
      default: return Colors.transparent;
    }
  }

  List<Map<String, String>> _dayActivities(DateTime day) {
    final key = _dateKey(day);
    final result = <Map<String, String>>[];
    for (final h in _habits) {
      final logs = _allLogs[h.id.toString()] ?? {};
      if (logs.containsKey(key)) {
        result.add({'habitName': h.name, 'status': logs[key]!});
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier de suivi'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime(2024, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                onDaySelected: (selected, focused) => setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
                onPageChanged: (f) => setState(() => _focusedDay = f),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (_, day, __) {
                    final status = _globalStatus(day);
                    final color = _statusColor(status);
                    if (color == Colors.transparent) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: cs.primary.withOpacity(.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: cs.primary, shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, titleCentered: true,
                ),
              ),

              // Légende
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: Colors.green, label: 'Réussi'),
                    const SizedBox(width: 16),
                    _Legend(color: Colors.red, label: 'Raté'),
                    const SizedBox(width: 16),
                    _Legend(color: Colors.orange, label: 'Reporté'),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Détail du jour
              Expanded(
                child: _selectedDay == null
                    ? Center(
                        child: Text(
                          'Appuyez sur un jour',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : _DayDetail(
                        day: _selectedDay!,
                        activities: _dayActivities(_selectedDay!),
                      ),
              ),
            ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _DayDetail extends StatelessWidget {
  final DateTime day;
  final List<Map<String, String>> activities;
  const _DayDetail({required this.day, required this.activities});

  IconData _icon(String s) {
    switch (s) {
      case 'done': return Icons.check_circle;
      case 'skipped': return Icons.cancel;
      default: return Icons.watch_later;
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'done': return Colors.green;
      case 'skipped': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _label(String s) {
    switch (s) {
      case 'done': return '✅ Fait';
      case 'skipped': return '❌ Raté';
      default: return '⏳ Reporté';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
    if (activities.isEmpty) {
      return Center(
        child: Text('Aucune activité le $dateStr',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Activités du $dateStr',
              style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = activities[i];
              final status = a['status']!;
              return ListTile(
                leading: Icon(_icon(status), color: _color(status)),
                title: Text(a['habitName']!,
                    style: const TextStyle(fontSize: 14)),
                trailing: Text(_label(status),
                    style: TextStyle(
                        color: _color(status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              );
            },
          ),
        ),
      ],
    );
  }
}