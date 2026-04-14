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
  List<Habit> _allHabits = [];
  List<Habit> _filtered = [];
  int _totalPoints = 0;
  int _doneToday = 0;
  bool _loading = true;
  String _search = '';
  String _filterCat = 'Tous';

  static const _cats = [
    'Tous','Santé','Sport','Apprentissage','Bien-être','Productivité','Autre'
  ];
  static const _quotes = [
    "La discipline forge le caractère.",
    "Chaque jour est une nouvelle chance.",
    "Les petits pas mènent loin.",
    "La constance crée l'excellence.",
    "Aujourd'hui est le bon moment",
  ];
  String get _quote => _quotes[DateTime.now().day % _quotes.length];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final habits = await _service.getHabits();
    final pts = await _service.getTotalPoints();
    final done = await _service.getHabitsDoneToday();
    if (!mounted) return;
    _allHabits = habits;
    _applyFilter();
    setState(() {
      _totalPoints = pts;
      _doneToday = done;
      _loading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allHabits.where((h) {
        final matchCat = _filterCat == 'Tous' || h.category == _filterCat;
        final matchSearch = _search.isEmpty ||
            h.name.toLowerCase().contains(_search.toLowerCase());
        return matchCat && matchSearch;
      }).toList();
    });
  }

  IconData _icon(String cat) {
    switch (cat) {
      case "Sport": return Icons.fitness_center;
      case "Apprentissage": return Icons.menu_book;
      case "Bien-être": return Icons.spa_outlined;
      case "Productivité": return Icons.rocket_launch_outlined;
      case "Santé": return Icons.favorite;
      default: return Icons.star;
    }
  }

  Color _color(String cat) {
    switch (cat) {
      case "Sport": return const Color(0xFFFF6B35);
      case "Apprentissage": return const Color(0xFF4A90D9);
      case "Bien-être": return const Color(0xFF9B59B6);
      case "Productivité": return const Color(0xFF1ABC9C);
      case "Santé": return const Color(0xFFE74C3C);
      default: return const Color(0xFF27AE60);
    }
  }

  Future<void> _confirmDelete(Habit h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Supprimer ?"),
        content: Text('Supprimer "${h.name}" définitivement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
    if (ok == true) { await _service.deleteHabit(h.id!); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F4F8),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [

            // ════════════════════════════════════════════════════════════
            // HERO HEADER
            // ════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF52B788)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre + Points
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Mes Habitudes",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5)),
                              ],
                            ),
                            // Badge points
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1.5),
                              ),
                              child: Row(children: [
                                const Text("🏆", style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text("$_totalPoints pts",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 3 Stats cards
                        Row(children: [
                          _StatCard(
                            icon: "📋",
                            value: "${_allHabits.length}",
                            label: "TOTAL",
                            gradient: const [Color(0xFF40916C), Color(0xFF52B788)],
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: "✅",
                            value: "$_doneToday",
                            label: "AUJOURD'HUI",
                            gradient: const [Color(0xFF1D6A96), Color(0xFF2196F3)],
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                             icon: "",
                            value: _allHabits.isEmpty
                                ? "0%"
                                : "${(_doneToday * 100 ~/ _allHabits.length)}%",
                            label: "TAUX",
                            gradient: const [Color(0xFFB5451B), Color(0xFFFF6B35)],
                          ),
                        ]),
                        const SizedBox(height: 20),

                        // Citation du jour
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            const Text("💡", style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_quote,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4)),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ════════════════════════════════════════════════════════════
            // RECHERCHE + FILTRES
            // ════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(children: [
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2A38) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (v) { _search = v; _applyFilter(); },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Rechercher une habitude...",
                        hintStyle: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: cs.onSurfaceVariant, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filtres catégories
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cats.length,
                      itemBuilder: (_, i) {
                        final cat = _cats[i];
                        final sel = cat == _filterCat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _filterCat = cat);
                              _applyFilter();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: sel
                                    ? const LinearGradient(colors: [
                                        Color(0xFF2D6A4F),
                                        Color(0xFF52B788)
                                      ])
                                    : null,
                                color: sel
                                    ? null
                                    : (isDark
                                        ? const Color(0xFF1E2A38)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: sel
                                          ? Colors.white
                                          : cs.onSurfaceVariant)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Titre section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_filtered.length} habitude(s)",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: cs.onSurface)),
                      Icon(Icons.sort, color: cs.onSurfaceVariant, size: 20),
                    ],
                  ),
                ]),
              ),
            ),

            // ════════════════════════════════════════════════════════════
            // LISTE HABITUDES
            // ════════════════════════════════════════════════════════════
            if (_loading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (_filtered.isEmpty)
              SliverFillRemaining(child: _EmptyView())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final h = _filtered[i];
                      return _HabitTile(
                        habit: h,
                        icon: _icon(h.category),
                        color: _color(h.category),
                        isDark: isDark,
                        onMarkDone: () async {
                          final ok = await _service.markDone(h.id!);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? "🎉 +10 pts ! Excellent !"
                                : "✅ Déjà complété aujourd'hui"),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: ok ? Colors.green : Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ));
                          _load();
                        },
                        onEdit: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AddHabitScreen(habit: h)));
                          _load();
                        },
                        onDelete: () => _confirmDelete(h),
                      );
                    },
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B4332), Color(0xFF52B788)],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddHabitScreen()));
            _load();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  
}

// ════════════════════════════════════════════════════════════════════════════
// STAT CARD (header)
// ════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String icon, value, label;
  final List<Color> gradient;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HABIT TILE
// ════════════════════════════════════════════════════════════════════════════

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onMarkDone, onEdit, onDelete;

  const _HabitTile({
    required this.habit,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onMarkDone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
        // Ligne colorée à gauche
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                // Icône avec gradient
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),

                // Nom + badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 8),
                      Row(children: [
                        // Catégorie pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(habit.category,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        // Points
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Text("🏆",
                                style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text("${habit.points} pts",
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        // Streak
                        FutureBuilder<int>(
                          future: HabitService().getStreak(habit.id!),
                          builder: (_, snap) {
                            if (snap.hasData && snap.data! > 0) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(children: [
                                  const Text("🔥",
                                      style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 4),
                                  Text("${snap.data}",
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange)),
                                ]),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ]),
                    ],
                  ),
                ),

                // Boutons action
                Column(
                  children: [
                    // Check button
                    GestureDetector(
                      onTap: onMarkDone,
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Menu
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: Icon(Icons.more_vert,
                          color: cs.onSurfaceVariant, size: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text("Modifier"),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            SizedBox(width: 10),
                            Text("Supprimer",
                                style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY VIEW
// ════════════════════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52B788).withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_task,
                size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text("Aucune habitude",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text("Commencez votre parcours en\najoutant votre première habitude ! 🚀",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}