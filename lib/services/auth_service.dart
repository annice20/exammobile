import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';

class AuthService {
  final _db = DB.instance;

  String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<bool> register(String username, String password) async {
    try {
      final box = _db.userBox;

      // Vérification manuelle du doublon
      final userExists = box.values.any(
        (u) => u['username'] == username.trim(),
      );

      if (userExists) {
        print("L'utilisateur existe déjà dans Hive");
        return false;
      }

      await box.add({'username': username.trim(), 'password': _hash(password)});

      print("INSCRIPTION VALIDÉE DANS HIVE !");
      return true;
    } catch (e) {
      print("ERREUR LORS DE L'INSCRIPTION : $e");
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final hashedPassword = _hash(password);
      final user = _db.userBox.values.firstWhere(
        (u) =>
            u['username'] == username.trim() && u['password'] == hashedPassword,
        orElse: () => null,
      );

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username.trim());
        return true;
      }
      return false;
    } catch (e) {
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
