import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/database/database_helper.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Suivi Temporel")),
      body: TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: DateTime.utc(2026, 01, 01),
        lastDay: DateTime.now(),
        // On charge les petits points sous les dates depuis Hive
        eventLoader: (day) {
          final dateKey =
              "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
          return DB.instance.logBox.values
              .where((log) => log['date'] == dateKey)
              .toList();
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
