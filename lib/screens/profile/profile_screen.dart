

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/habit_service.dart';
import '../../services/pin_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth        = AuthService();
  final _habitService= HabitService();
  final _pinService  = PinService();

  String _username    = '';
  int    _totalPoints = 0;
  int    _habitCount  = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final name    = await _auth.getUsername();
    final pts     = await _habitService.getTotalPoints();
    final habits  = await _habitService.getHabits();
    if (!mounted) return;
    setState(() {
      _username    = name;
      _totalPoints = pts;
      _habitCount  = habits.length;
    });
  }

  // ── PIN ──────────────────────────────────────────────────────────────────
  Future<void> _showPinDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Définir un code PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Code PIN (4 chiffres)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.length == 4) {
                await _pinService.setPin(ctrl.text);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code PIN activé ✅')));
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }



  // ── RESET STATS ──────────────────────────────────────────────────────────
  Future<void> _resetStats() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réinitialiser les statistiques ?'),
        content: const Text('Tous les logs et points seront effacés. Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _habitService.resetAllStats();
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistiques réinitialisées')));
    }
  }

  // ── DÉCONNEXION ──────────────────────────────────────────────────────────
  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: cs.primaryContainer,
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cs.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(_username,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Badges stats
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Badge(icon: Icons.emoji_events, color: Colors.amber, label: '$_totalPoints pts'),
              const SizedBox(width: 12),
              _Badge(icon: Icons.checklist, color: cs.primary, label: '$_habitCount habitudes'),
            ]),

            const SizedBox(height: 32),

            // Actions
            _ActionTile(
              icon: Icons.lock_outline, color: Colors.blue,
              label: 'Code PIN',
              subtitle: 'Verrouiller l\'accès à l\'application',
              onTap: _showPinDialog,
            ),
            
            
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.restart_alt, color: Colors.orange,
              label: 'Réinitialiser les stats',
              subtitle: 'Effacer tous les logs et points',
              onTap: _resetStats,
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.logout, color: Colors.red,
              label: 'Déconnexion',
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon; final Color color; final String label;
  const _Badge({required this.icon, required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final Color color;
  final String label; final String? subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon, required this.color,
    required this.label, this.subtitle, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.withOpacity(.2)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withOpacity(.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    ),
  );
}

