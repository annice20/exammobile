import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/candidat_tile.dart';
import '../widgets/misc_widgets.dart';

// ─── PAGE ─────────────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late Future<DashboardData> _future;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _future = DashboardService.fetch();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = DashboardService.fetch();
      _animCtrl
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: FutureBuilder<DashboardData>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
            );
          }
          if (snap.hasError) {
            return ErrorView(error: snap.error.toString(), onRetry: _refresh);
          }
          return _DashboardContent(
            data: snap.data!,
            animation: _animCtrl,
            onRefresh: _refresh,
          );
        },
      ),
    );
  }
}

// ─── CONTENU ─────────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  final AnimationController animation;
  final VoidCallback onRefresh;

  const _DashboardContent({
    required this.data,
    required this.animation,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final maxVotes = data.resultats.isEmpty
        ? 1
        : data.resultats.map((r) => r.votes).reduce((a, b) => a > b ? a : b);

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        _buildStatsSection(),
        _buildElectionSection(maxVotes),
      ],
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
    expandedHeight: 130,
    pinned: true,
    backgroundColor: const Color(0xFF0D1B2A),
    flexibleSpace: FlexibleSpaceBar(
      title: const Text(
        'Tableau de Bord',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B3A6B), Color(0xFF0D1B2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4FC3F7),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF4FC3F7), size: 8),
                    SizedBox(width: 6),
                    Text(
                      'En ligne',
                      style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
        onPressed: onRefresh,
      ),
      const SizedBox(width: 8),
    ],
  );

  SliverPadding _buildStatsSection() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Statistiques Générales'),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final crossCount = isWide ? 4 : 2;
                const cardHeight = 110.0;

                final statCards = [
                  StatCard(
                    index: 0,
                    icon: Icons.people_alt_rounded,
                    label: 'Citoyens',
                    value: data.stats.totalCitoyens,
                    color: const Color(0xFF4FC3F7),
                    animation: animation,
                  ),
                  StatCard(
                    index: 1,
                    icon: Icons.badge_rounded,
                    label: 'CIN Délivrées',
                    value: data.stats.cinDelivered,
                    color: const Color(0xFF81C784),
                    animation: animation,
                  ),
                  StatCard(
                    index: 2,
                    icon: Icons.hourglass_top_rounded,
                    label: 'En Attente',
                    value: data.stats.pendingRequests,
                    color: const Color(0xFFFFB74D),
                    animation: animation,
                  ),
                  StatCard(
                    index: 3,
                    icon: Icons.how_to_vote_rounded,
                    label: 'Total Votes',
                    value: data.stats.totalVotes,
                    color: const Color(0xFFCE93D8),
                    animation: animation,
                  ),
                ];

                final rows = <Widget>[];
                for (var i = 0; i < statCards.length; i += crossCount) {
                  final end = (i + crossCount).clamp(0, statCards.length);
                  final rowCards = statCards.sublist(i, end);
                  rows.add(
                    Row(
                      children: [
                        for (var j = 0; j < rowCards.length; j++) ...[
                          if (j > 0) const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: cardHeight,
                              child: rowCards[j],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                  if (end < statCards.length)
                    rows.add(const SizedBox(height: 14));
                }

                return Column(children: rows);
              },
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildElectionSection(int maxVotes) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
    sliver: SliverToBoxAdapter(
      child: data.resultats.isEmpty
          ? const NoElectionCard()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                  'Résultats : ${data.electionTitre ?? "Élection Active"}',
                ),
                const SizedBox(height: 14),
                ...List.generate(data.resultats.length, (i) {
                  return CandidatTile(
                    index: i,
                    resultat: data.resultats[i],
                    maxVotes: maxVotes,
                    animation: animation,
                    isFirst: i == 0,
                  );
                }),
              ],
            ),
    ),
  );
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white54,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  );
}
