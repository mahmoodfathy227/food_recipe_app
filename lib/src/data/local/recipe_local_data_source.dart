import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/utils/logger.dart';

const _kFavorites = 'favorites';
const _kViewed = 'viewed';
const _kDiscovery = 'last_discovery';
const _dbName = 'recipe_store.db';
const _v = 1;

/// SQLite persistence for favorites, last discovery bundle, and viewed recipe payloads.
class RecipeLocalDataSource {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    debugPrint('[RecipeLocalDataSource] opening db at $path');
    AppLogger.info('[RecipeLocalDataSource] open $path');
    return openDatabase(
      path,
      version: _v,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_kFavorites (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE $_kViewed (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            viewed_at INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE $_kDiscovery (
            key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
      },
    );
  }

  Future<void> storeDiscoveryBundle(String json) async {
    final db = await database;
    await db.insert(
      _kDiscovery,
      {
        'key': 'default',
        'payload': json,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('[RecipeLocalDataSource] stored discovery cache');
  }

  Future<String?> getDiscoveryBundle() async {
    final db = await database;
    final rows = await db.query(_kDiscovery, where: 'key = ?', whereArgs: const ['default']);
    if (rows.isEmpty) return null;
    return rows.first['payload'] as String?;
  }

  Future<void> saveViewed(RecipeDetail detail) async {
    final db = await database;
    await db.insert(
      _kViewed,
      {
        'id': detail.id,
        'payload': detail.toJsonString(),
        'viewed_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('[RecipeLocalDataSource] cached viewed ${detail.id}');
  }

  Future<RecipeDetail?> getCachedDetail(String id) async {
    final db = await database;
    final loved = await db.query(_kFavorites, where: 'id = ?', whereArgs: [id]);
    if (loved.isNotEmpty) {
      final map = jsonDecode(loved.first['payload']! as String) as Map<String, dynamic>;
      return RecipeDetail.fromJsonMap(map);
    }
    final viewed = await db.query(_kViewed, where: 'id = ?', whereArgs: [id]);
    if (viewed.isNotEmpty) {
      final map = jsonDecode(viewed.first['payload']! as String) as Map<String, dynamic>;
      return RecipeDetail.fromJsonMap(map);
    }
    return null;
  }

  Future<List<RecipeDetail>> allFavorites() async {
    final db = await database;
    final rows = await db.query(_kFavorites, orderBy: 'updated_at DESC');
    return rows
        .map((r) => RecipeDetail.fromJsonMap(jsonDecode(r['payload']! as String) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isFavorite(String id) async {
    final db = await database;
    final c = await db.rawQuery('SELECT COUNT(*) as c FROM $_kFavorites WHERE id = ?', [id]);
    return (c.first['c'] as int? ?? 0) > 0;
  }

  Future<void> setFavorite(RecipeDetail detail) async {
    final db = await database;
    await db.insert(
      _kFavorites,
      {
        'id': detail.id,
        'payload': jsonEncode(detail.toFullJsonMap()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('[RecipeLocalDataSource] favorited ${detail.id}');
  }

  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db.delete(_kFavorites, where: 'id = ?', whereArgs: [id]);
    debugPrint('[RecipeLocalDataSource] removed favorite $id');
  }

  Future<void> clearViewed() async {
    final db = await database;
    await db.delete(_kViewed);
  }
}
