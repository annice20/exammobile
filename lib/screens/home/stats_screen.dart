import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _service = HabitService();
  List<Habit> _habits = [];
  List<Map<String, dynamic>> _weeklyStats = [];
  Map<String, int> _pointsByCategory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final habits = await _service.getHabits();
    final weekly = await _service.getWeeklyStats();
    final Map<String, int> cats = {};
    for (final h in habits) {
      cats[h.category] = (cats[h.category] ?? 0) + h.points;
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _weeklyStats = weekly;
      _pointsByCategory = cats;
      _loading = false;
    });
  }

  Color _catColor(String cat) {
    switch (cat) {
      case "Sport": return const Color(0xFFFF6B35);
      case "Apprentissage": return const Color(0xFF4A90D9);
      case "Bien-être": return const Color(0xFF9B59B6);
      case "Productivité": return const Color(0xFF1ABC9C);
      case "Santé": return const Color(0xFFE74C3C);
      default: return const Color(0xFF27AE60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Statistiques"),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Graphique hebdomadaire
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Activité des 7 derniers jours",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 160,
                            child: _weeklyStats.isEmpty
                                ? Center(
                                    child: Text("Aucune donnée",
                                        style: TextStyle(
                                            color: cs.onSurfaceVariant)))
                                : BarChart(_buildBarChart(cs)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Répartition par catégorie
                  if (_pointsByCategory.isNotEmpty) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Répartition par catégorie",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  sections: _pointsByCategory.entries
                                      .map((e) => PieChartSectionData(
                                            value: e.value
                                                .toDouble()
                                                .clamp(1, double.infinity),
                                            title: e.key,
                                            radius: 65,
                                            color: _catColor(e.key),
                                            titleStyle: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ))
                                      .toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Légende
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: _pointsByCategory.entries.map((e) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(
                                        color: _catColor(e.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                        "${e.key}: ${e.value} pts",
                                        style:
                                            const TextStyle(fontSize: 12)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Taux de réussite par habitude
                  if (_habits.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Taux de réussite ce mois",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ..._habits.map((h) => _HabitRateRow(
                                habit: h, service: _service)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  BarChartData _buildBarChart(ColorScheme cs) {
    final maxY = _weeklyStats
            .map((d) => (d["count"] as int).toDouble())
            .fold(0.0, (a, b) => a > b ? a : b) +
        1;

    return BarChartData(
      maxY: maxY < 2 ? 2 : maxY,
      barGroups: _weeklyStats.asMap().entries.map((e) {
        final count = (e.value["count"] as int).toDouble();
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: count,
              gradient: count > 0
                  ? LinearGradient(
                      colors: [cs.primary, cs.secondary],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    )
                  : null,
              color: count > 0 ? null : cs.surfaceVariant,
              width: 22,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= _weeklyStats.length) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _weeklyStats[i]["label"] as String,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant),
                ),
              );
            },
          ),
        ),
        leftTitles:
            AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }
}

class _HabitRateRow extends StatefulWidget {
  final Habit habit;
  final HabitService service;
  const _HabitRateRow({required this.habit, required this.service});
  @override
  State<_HabitRateRow> createState() => _HabitRateRowState();
}

class _HabitRateRowState extends State<_HabitRateRow> {
  double _rate = 0;

  @override
  void initState() {
    super.initState();
    widget.service.getMonthlyRate(widget.habit.id!).then((r) {
      if (mounted) setState(() => _rate = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.habit.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              Text("${_rate.toStringAsFixed(0)}%",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _rate >= 70
                          ? Colors.green
                          : _rate >= 40
                              ? Colors.orange
                              : Colors.red,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _rate / 100,
              minHeight: 8,
              backgroundColor: cs.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                _rate >= 70
                    ? Colors.green
                    : _rate >= 40
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}