import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
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
  final _auth = AuthService();
  final _habitService = HabitService();
  final _pinService = PinService();

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

  // Fonction pour le Code PIN
  Future<void> _showPinDialog() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sécuriser l'accès"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Nouveau Code PIN (4 chiffres)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                await _pinService.setPin(controller.text);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Code PIN activé")),
                );
              }
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  // Fonction Export JSON améliorée (Téléchargement réel)
  Future<void> _exportJson() async {
    final data = await _habitService.exportHabitsToJson();

    // Création du fichier pour le navigateur
    final bytes = utf8.encode(data);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "data_export.json")
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚀 Fichier JSON téléchargé !")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Mon Profil"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: cs.primaryContainer,
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : "?",
                style: TextStyle(fontSize: 32, color: cs.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _username,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Score
            Chip(
              label: Text("$_totalPoints points"),
              avatar: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
            ),

            const SizedBox(height: 40),

            // --- LISTE DES ACTIONS ---
            _ActionTile(
              icon: Icons.lock_outline,
              label: "Code PIN",
              subtitle: "Verrouiller l'accès aux données",
              color: Colors.blue,
              onTap: _showPinDialog,
            ),

            const SizedBox(height: 12),

            _ActionTile(
              icon: Icons.file_download_outlined,
              label: "Sauvegarde JSON",
              subtitle: "Exporter pour importer ailleurs",
              color: Colors.green,
              onTap: _exportJson,
            ),

            const SizedBox(height: 12),

            _ActionTile(
              icon: Icons.logout,
              label: "Déconnexion",
              color: Colors.red,
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
    );
  }
}

// Widget réutilisable pour les boutons du profil
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
