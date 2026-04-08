import 'package:hive_flutter/hive_flutter.dart';

class DB {
  static final DB instance = DB._init();
  DB._init();

  late Box _userBox;
  late Box _habitBox;
  late Box _logBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // On ouvre les boîtes (équivalent des tables)
    _userBox = await Hive.openBox('users');
    _habitBox = await Hive.openBox('habits');
    _logBox = await Hive.openBox('logs');
  }

  Box get userBox => _userBox;
  Box get habitBox => _habitBox;
  Box get logBox => _logBox;
}
