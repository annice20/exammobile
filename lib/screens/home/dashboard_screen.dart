import 'package:flutter/material.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';
import '../habit/add_habit_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  final _service = HabitService();
  List<Habit> _habits = [];
  int _totalPoints = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final habits = await _service.getHabits();
    final pts = await _service.getTotalPoints();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _totalPoints = pts;
      _loading = false;
    });
  }

  // Catégorie → icône
  IconData _categoryIcon(String cat) {
    switch (cat) {
      case "Sport":
        return Icons.fitness_center;
      case "Apprentissage":
        return Icons.menu_book;
      case "Bien-être":
        return Icons.spa_outlined;
      case "Productivité":
        return Icons.rocket_launch_outlined;
      case "Santé":
        return Icons.favorite_outline;
      default:
        return Icons.star_outline;
    }
  }

  Color _categoryColor(String cat, ColorScheme cs) {
    switch (cat) {
      case "Sport":
        return Colors.orange;
      case "Apprentissage":
        return Colors.blue;
      case "Bien-être":
        return Colors.purple;
      case "Productivité":
        return Colors.teal;
      case "Santé":
        return Colors.red;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── AppBar avec points ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text("Mes Habitudes"),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(right: 20, bottom: 52),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$_totalPoints pts",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── Contenu ─────────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_habits.isEmpty)
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_add,
                      size: 80,
                      color: cs.onSurfaceVariant.withOpacity(.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Aucune habitude pour l'instant",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Appuyez sur + pour commencer",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _HabitCard(
                      habit: _habits[i],
                      icon: _categoryIcon(_habits[i].category),
                      color: _categoryColor(_habits[i].category, cs),
                      onMarkDone: () async {
                        final success = await _service.markDone(_habits[i].id!);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? "✅ +10 pts ! Bravo !"
                                  : "Déjà complété aujourd'hui",
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        _load();
                      },
                      onDelete: () async {
                        await _service.deleteHabit(_habits[i].id!);
                        _load();
                      },
                    ),
                    childCount: _habits.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Ajouter"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHabitScreen()),
          );
          _load();
        },
      ),
    );
  }
}

// ── Widget carte habitude ───────────────────────────────────────────────────

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final IconData icon;
  final Color color;
  final VoidCallback onMarkDone;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.icon,
    required this.color,
    required this.onMarkDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Chip(
              label: Text(habit.category, style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              backgroundColor: color.withOpacity(.12),
              side: BorderSide.none,
            ),
            const SizedBox(width: 8),
            Icon(Icons.emoji_events, size: 14, color: Colors.amber),
            const SizedBox(width: 2),
            Text(
              "${habit.points} pts",
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Marquer comme fait",
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: onMarkDone,
            ),
            IconButton(
              tooltip: "Supprimer",
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
