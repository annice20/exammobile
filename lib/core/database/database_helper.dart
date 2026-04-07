import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class DB {
  static final DB instance = DB._init();
  static Database? _db;
  static Completer<Database>? _dbOpenCompleter;

  DB._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_dbOpenCompleter != null) return _dbOpenCompleter!.future;

    _dbOpenCompleter = Completer<Database>();
    try {
      final db = await _initDB();
      _db = db;
      _dbOpenCompleter!.complete(db);
      return db;
    } catch (e) {
      _dbOpenCompleter!.completeError(e);
      _dbOpenCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDB() async {
    const String name = 'habit_final_v5.db';
    String path = name;

    if (!kIsWeb) {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, name);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE habits(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            points INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }
}
