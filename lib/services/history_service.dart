import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/history_entry.dart';

class HistoryService with ChangeNotifier {
  static Database? _database;
  final List<HistoryEntry> _recentVisits = [];
  bool _isLoading = false;

  List<HistoryEntry> get recentVisits => _recentVisits;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'cultura_history.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE history(id INTEGER PRIMARY KEY AUTOINCREMENT, city TEXT, state TEXT, timestamp TEXT, keywords TEXT, culturalSummary TEXT)',
          );
        },
        version: 1,
      );

      await _loadRecentVisits();
    } catch (e) {
      print('Error initializing database: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecentVisits() async {
    if (_database == null) return;

    final List<Map<String, dynamic>> maps =
    await _database!.query('history', orderBy: 'timestamp DESC', limit: 10);

    _recentVisits.clear();
    _recentVisits.addAll(
      List.generate(maps.length, (i) {
        return HistoryEntry.fromJson({
          ...maps[i],
          'keywords': json.decode(maps[i]['keywords']),
        });
      }),
    );
    notifyListeners();
  }

  Future<void> addVisit(String city, String state, List<String> keywords) async {
    if (_database == null) return;

    final entry = HistoryEntry(
      city: city,
      state: state,
      timestamp: DateTime.now(),
      keywords: keywords,
    );

    await _database!.insert('history', entry.toJson());
    await _loadRecentVisits();
  }

  Future<void> updateSummary(int id, String summary) async {
    if (_database == null) return;

    await _database!.update(
      'history',
      {'culturalSummary': summary},
      where: 'id = ?',
      whereArgs: [id],
    );

    await _loadRecentVisits();
  }

  Future<void> clearHistory() async {
    if (_database == null) return;

    await _database!.delete('history');
    _recentVisits.clear();
    notifyListeners();
  }
}