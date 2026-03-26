import 'dashboard_stats.dart';
import 'resultat.dart';

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
