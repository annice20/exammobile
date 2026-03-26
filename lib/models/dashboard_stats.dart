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
