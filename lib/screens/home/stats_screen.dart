import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/database/database_helper.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Statistiques")),
      body: ValueListenableBuilder(
        valueListenable: DB.instance.habitBox.listenable(),
        builder: (context, Box box, _) {
          // 1. Calculer les points par catégorie
          Map<String, int> stats = {};
          for (var habit in box.values) {
            final cat = habit['category'] ?? "Autre";
            stats[cat] = (stats[cat] ?? 0) + (habit['points'] as int? ?? 0);
          }

          if (stats.isEmpty) return const Center(child: Text("Aucune donnée"));

          return Padding(
            padding: const EdgeInsets.all(20),
            child: PieChart(
              PieChartData(
                sections: stats.entries
                    .map(
                      (e) => PieChartSectionData(
                        value: e.value.toDouble(),
                        title: "${e.key}\n${e.value}pts",
                        radius: 60,
                        color:
                            Colors.primaries[stats.keys.toList().indexOf(
                                  e.key,
                                ) %
                                Colors.primaries.length],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
