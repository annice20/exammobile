import 'package:flutter/material.dart';
import '../models/resultat.dart';

class CandidatTile extends StatelessWidget {
  final int index;
  final Resultat resultat;
  final int maxVotes;
  final AnimationController animation;
  final bool isFirst;

  const CandidatTile({
    super.key,
    required this.index,
    required this.resultat,
    required this.maxVotes,
    required this.animation,
    required this.isFirst,
  });

  static const _rankColors = [
    Color(0xFFFFD700), // or
    Color(0xFFB0BEC5), // argent
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    final pct = maxVotes > 0 ? resultat.votes / maxVotes : 0.0;
    final delay = 0.3 + index * 0.1;
    final barColor = index < _rankColors.length
        ? _rankColors[index]
        : const Color(0xFF4FC3F7);

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
                _RankBadge(rank: index + 1, color: barColor),
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
                      const Text(
                        'Candidat',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _VoteCount(votes: resultat.votes, color: barColor),
              ],
            ),
            const SizedBox(height: 12),
            _VoteBar(pct: pct, index: index, color: barColor),
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

// ── Sous-widgets privés ───────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      shape: BoxShape.circle,
      border: Border.all(color: color.withOpacity(0.4), width: 1),
    ),
    child: Center(
      child: Text(
        '$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ),
  );
}

class _VoteCount extends StatelessWidget {
  final int votes;
  final Color color;

  const _VoteCount({required this.votes, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        '$votes',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      const Text(
        'votes',
        style: TextStyle(color: Colors.white38, fontSize: 10),
      ),
    ],
  );
}

class _VoteBar extends StatelessWidget {
  final double pct;
  final int index;
  final Color color;

  const _VoteBar({required this.pct, required this.index, required this.color});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + index * 150),
      tween: Tween(begin: 0, end: pct),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => LinearProgressIndicator(
        value: v,
        minHeight: 6,
        backgroundColor: Colors.white.withOpacity(0.07),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    ),
  );
}
