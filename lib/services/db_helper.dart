import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';
import 'web_storage_stub.dart'
    if (dart.library.js_interop) 'web_storage_web.dart';

class DBHelper {
  static Database? _database;

  static var _webTripsCache;
  static var _webNextId = 1;
  static var _webPhotosCache;

  static const _defaultPhotos = [
    {
      'title': 'Biển xanh',
      'url': 'https://picsum.photos/id/1015/500/500',
    },
    {
      'title': 'Đồi thông',
      'url': 'https://picsum.photos/id/1018/500/500',
    },
    {
      'title': 'Rừng cây',
      'url': 'https://picsum.photos/id/1019/500/500',
    },
    {
      'title': 'Hoàng hôn',
      'url': 'https://picsum.photos/id/1039/500/500',
    },
    {
      'title': 'Cảnh núi',
      'url': 'https://picsum.photos/id/1043/500/500',
    },
    {
      'title': 'Chuyến đi xa',
      'url': 'https://picsum.photos/id/1051/500/500',
    },
  ];

  static Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'travel_diary.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            location TEXT,
            startDate TEXT,
            budget REAL,
            itinerary TEXT
          )
        ''');
        await _createPhotosTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPhotosTable(db);
        }
      },
    );
    return _database!;
  }

  static Future<void> _createPhotosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS album_photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        url TEXT
      )
    ''');
    for (final p in _defaultPhotos) {
      await db.insert('album_photos', {
        'title': p['title'] ?? '',
        'url': p['url'] ?? '',
      });
    }
  }

  static _ensureWebTrips() {
    if (_webTripsCache != null) return _webTripsCache;
    var loaded = [];
    try {
      final raw = readWebTripsJson();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              loaded.add(Trip.fromMap(Map.from(item)));
            }
          }
        }
      }
    } catch (_) {}

    var maxId = 0;
    for (final t in loaded) {
      final trip = t as Trip;
      if (trip.id != null && trip.id! > maxId) {
        maxId = trip.id!;
      }
    }
    _webNextId = maxId + 1;
    _webTripsCache = loaded;
    return _webTripsCache;
  }

  static void _saveWebTrips() {
    final list = _ensureWebTrips() as List;
    final rawMaps = [];
    for (final item in list) {
      final t = item as Trip;
      rawMaps.add({
        'id': t.id,
        'name': t.name,
        'location': t.location,
        'startDate': t.startDate,
        'budget': t.budget,
        'itinerary': t.itinerary,
      });
    }
    writeWebTripsJson(jsonEncode(rawMaps));
  }

  static Future<int> insertTrip(Trip trip) async {
    if (kIsWeb) {
      final list = _ensureWebTrips() as List;
      final id = _webNextId++;
      list.insert(
        0,
        Trip(
          id: id,
          name: trip.name,
          location: trip.location,
          startDate: trip.startDate,
          budget: trip.budget,
          itinerary: trip.itinerary,
        ),
      );
      _saveWebTrips();
      return id;
    }

    final db = await database;
    return await db.insert('trips', trip.toMap());
  }

  static Future<List<Trip>> getTrips() async {
    if (kIsWeb) {
      final list = _ensureWebTrips() as List;
      final result = <Trip>[];
      for (final item in list) {
        result.add(item as Trip);
      }
      return result;
    }

    try {
      final db = await database;
      final maps = await db.query('trips', orderBy: 'id DESC');
      return maps.map((e) => Trip.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<int> updateTrip(Trip trip) async {
    if (kIsWeb) {
      final list = _ensureWebTrips() as List;
      final index = list.indexWhere((t) => (t as Trip).id == trip.id);
      if (index != -1) {
        list[index] = trip;
      }
      _saveWebTrips();
      return 1;
    }

    final db = await database;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  static Future<int> deleteTrip(int id) async {
    if (kIsWeb) {
      final list = _ensureWebTrips() as List;
      list.removeWhere((t) => (t as Trip).id == id);
      _saveWebTrips();
      return 1;
    }

    final db = await database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  static _ensureWebPhotos() {
    if (_webPhotosCache != null) return _webPhotosCache;
    var list = [];
    for (var i = 0; i < _defaultPhotos.length; i++) {
      list.add({
        'id': i + 1,
        'title': _defaultPhotos[i]['title'] ?? '',
        'url': _defaultPhotos[i]['url'] ?? '',
      });
    }
    _webPhotosCache = list;
    return _webPhotosCache;
  }

  static Future getPhotos() async {
    if (kIsWeb) {
      var cache = _ensureWebPhotos();
      var copy = [];
      for (var item in cache) {
        copy.add({
          'id': item['id'],
          'title': item['title'],
          'url': item['url'],
        });
      }
      return copy;
    }

    try {
      final db = await database;
      return await db.query('album_photos', orderBy: 'id DESC');
    } catch (_) {
      return [];
    }
  }

  static Future<void> insertPhoto({
    required String title,
    required String url,
  }) async {
    if (kIsWeb) {
      var current = _ensureWebPhotos();
      var maxId = 0;
      for (final item in current) {
        final idVal = item['id'] is int
            ? item['id'] as int
            : int.tryParse(item['id'].toString()) ?? 0;
        if (idVal > maxId) maxId = idVal;
      }
      current.insert(0, {
        'id': maxId + 1,
        'title': title,
        'url': url,
      });
      return;
    }

    final db = await database;
    await db.insert('album_photos', {
      'title': title,
      'url': url,
    });
  }

  static Future<void> deletePhoto(dynamic id) async {
    if (kIsWeb) {
      var current = _ensureWebPhotos();
      current.removeWhere((item) => item['id'].toString() == id.toString());
      return;
    }

    final db = await database;
    final intId = id is int ? id : int.tryParse(id.toString());
    if (intId != null) {
      await db.delete('album_photos', where: 'id = ?', whereArgs: [intId]);
    }
  }
}