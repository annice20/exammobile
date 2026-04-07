import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';

class AuthService {
  final _dbInstance = DB.instance;

  String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  // INSCRIPTION
  Future<bool> register(String username, String password) async {
    try {
      final db = await _dbInstance.database;
      await db.insert('users', {
        'username': username.trim(),
        'password': _hash(password),
      });
      return true;
    } catch (e) {
      print("Erreur inscription: $e");
      return false;
    }
  }

  // CONNEXION
  Future<bool> login(String username, String password) async {
    try {
      final db = await _dbInstance.database;
      final hashedPassword = _hash(password);

      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username.trim(), hashedPassword],
      );

      if (maps.isNotEmpty) {
        // ✅ Sauvegarde de la session hors de SQLite pour la stabilité
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username.trim());
        return true;
      }
      return false;
    } catch (e) {
      print("Erreur login: $e");
      return false;
    }
  }

  // RÉCUPÉRATION DE SESSION (Utilisé par Main.dart)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? "Utilisateur";
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
