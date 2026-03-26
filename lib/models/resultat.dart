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
