import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── MODÈLES ─────────────────────────────────────────────────────────────────

class DashboardStats {
  final int totalCitoyens;
  final int cinDelivered;
  final int pendingRequests;
  final int totalVotes;

  DashboardStats({
    required this.totalCitoyens,
    required this.cinDelivered,
    required this.pendingRequests,
    required this.totalVotes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalCitoyens: j['total_citoyens'] ?? 0,
    cinDelivered: j['cin_delivered'] ?? 0,
    pendingRequests: j['pending_requests'] ?? 0,
    totalVotes: j['total_votes'] ?? 0,
  );
}

class Resultat {
  final String nom;
  final String prenom;
  final int votes;

  Resultat({required this.nom, required this.prenom, required this.votes});

  factory Resultat.fromJson(Map<String, dynamic> j) => Resultat(
    nom: j['nomCandidat'] ?? '',
    prenom: j['prenomCandidat'] ?? '',
    votes: j['total_votes'] ?? 0,
  );
}

class DashboardData {
  final DashboardStats stats;
  final String? electionTitre;
  final List<Resultat> resultats;

  DashboardData({
    required this.stats,
    this.electionTitre,
    required this.resultats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    stats: DashboardStats.fromJson(j['stats'] ?? {}),
    electionTitre: j['electionTitre'],
    resultats: (j['resultats'] as List<dynamic>? ?? [])
        .map((e) => Resultat.fromJson(e))
        .toList(),
  );
}

// ─── SERVICE ─────────────────────────────────────────────────────────────────

class DashboardService {
  static const String baseUrl = 'http://localhost:5207/api/dashboardapi';

  static Future<DashboardData> fetch() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return DashboardData.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erreur ${response.statusCode}');
  }
}

// ─── PAGE PRINCIPALE ─────────────────────────────────────────────────────────

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
            return _ErrorView(error: snap.error.toString(), onRetry: _refresh);
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
        // ── App Bar ──────────────────────────────────────────────────────────
        SliverAppBar(
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
                    child: Row(
                      children: [
                        Container(
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
                              Icon(
                                Icons.circle,
                                color: Color(0xFF4FC3F7),
                                size: 8,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'En ligne',
                                style: TextStyle(
                                  color: Color(0xFF4FC3F7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
        ),

        // ── Statistiques ─────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Statistiques Générales'),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.0,
                  children: [
                    _StatCard(
                      index: 0,
                      icon: Icons.people_alt_rounded,
                      label: 'Citoyens',
                      value: data.stats.totalCitoyens,
                      color: const Color(0xFF4FC3F7),
                      animation: animation,
                    ),
                    _StatCard(
                      index: 1,
                      icon: Icons.badge_rounded,
                      label: 'CIN Délivrées',
                      value: data.stats.cinDelivered,
                      color: const Color(0xFF81C784),
                      animation: animation,
                    ),
                    _StatCard(
                      index: 2,
                      icon: Icons.hourglass_top_rounded,
                      label: 'En Attente',
                      value: data.stats.pendingRequests,
                      color: const Color(0xFFFFB74D),
                      animation: animation,
                    ),
                    _StatCard(
                      index: 3,
                      icon: Icons.how_to_vote_rounded,
                      label: 'Total Votes',
                      value: data.stats.totalVotes,
                      color: const Color(0xFFCE93D8),
                      animation: animation,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Résultats Élection ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
          sliver: SliverToBoxAdapter(
            child: data.resultats.isEmpty
                ? _NoElectionCard()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(
                        'Résultats : ${data.electionTitre ?? "Élection Active"}',
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(data.resultats.length, (i) {
                        final r = data.resultats[i];
                        return _CandidatTile(
                          index: i,
                          resultat: r,
                          maxVotes: maxVotes,
                          animation: animation,
                          isFirst: i == 0,
                        );
                      }),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white54,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  );
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final AnimationController animation;

  const _StatCard({
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.12;
    final slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic),
          ),
        );
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF162032),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CANDIDAT TILE ────────────────────────────────────────────────────────────

class _CandidatTile extends StatelessWidget {
  final int index;
  final Resultat resultat;
  final int maxVotes;
  final AnimationController animation;
  final bool isFirst;

  const _CandidatTile({
    required this.index,
    required this.resultat,
    required this.maxVotes,
    required this.animation,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxVotes > 0 ? resultat.votes / maxVotes : 0.0;
    final delay = 0.3 + index * 0.1;
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(
          delay.clamp(0, 1),
          (delay + 0.4).clamp(0, 1),
          curve: Curves.easeOut,
        ),
      ),
    );

    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFB0BEC5),
      const Color(0xFFCD7F32),
    ];
    final barColor = index < colors.length
        ? colors[index]
        : const Color(0xFF4FC3F7);

    return FadeTransition(
      opacity: fade,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162032),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFirst
                ? const Color(0xFFFFD700).withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: barColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${resultat.prenom} ${resultat.nom}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Candidat',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${resultat.votes}',
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      'votes',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 800 + index * 150),
                tween: Tween(begin: 0, end: pct),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: barColor.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NO ELECTION ─────────────────────────────────────────────────────────────

class _NoElectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFF162032),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: const Column(
      children: [
        Icon(Icons.how_to_vote_outlined, color: Colors.white24, size: 48),
        SizedBox(height: 12),
        Text(
          'Aucune élection active',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ─── ERROR VIEW ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFFF7043),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les données',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3A6B),
              foregroundColor: const Color(0xFF4FC3F7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
