import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/habit_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _habitService = HabitService();

  String _username = "";
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _auth.getUsername();
    final pts = await _habitService.getTotalPoints();
    if (!mounted) return;
    setState(() {
      _username = name;
      _totalPoints = pts;
    });
  }

  Future<void> _exportJson(BuildContext context) async {
    final json = await _habitService.exportHabitsToJson();
    if (!mounted) return;
    await Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Données copiées dans le presse-papiers (JSON)"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Mon Profil"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 52,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  _username.isNotEmpty ? _username[0].toUpperCase() : "?",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _username,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Badge points
              Chip(
                avatar: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 18,
                ),
                label: Text(
                  "$_totalPoints points",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.amber.withOpacity(.15),
                side: BorderSide.none,
              ),
              const SizedBox(height: 32),

              // Actions
              _ActionTile(
                icon: Icons.download_outlined,
                label: "Exporter mes données (JSON)",
                color: cs.primary,
                onTap: () => _exportJson(context),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.logout,
                label: "Se déconnecter",
                color: cs.error,
                onTap: () async {
                  await _auth.logout();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
