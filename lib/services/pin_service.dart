import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  Future setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("pin", pin);
  }

  Future<bool> checkPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("pin") == pin;
  }
}
