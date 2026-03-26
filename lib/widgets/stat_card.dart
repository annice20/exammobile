import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final AnimationController animation;

  const StatCard({
    super.key,
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
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
