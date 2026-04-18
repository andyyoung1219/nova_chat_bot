import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../data/nasa_api_data.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static Database? _database;
  final ValueNotifier<bool> updateNotifier = ValueNotifier(false);

  factory StorageService() => _instance;

  StorageService._internal();

  /// 取得資料庫實例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化資料庫
  Future<Database> _initDatabase() async {
    // 取得資料庫檔案路徑
    String path = join(await getDatabasesPath(), 'nasa_messenger.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 收藏表
        await db.execute(
          'CREATE TABLE favorites(date TEXT PRIMARY KEY, title TEXT, explanation TEXT, url TEXT, media_type TEXT)',
        );
        // cache 表
        await db.execute(
          'CREATE TABLE cache(date TEXT PRIMARY KEY, title TEXT, explanation TEXT, url TEXT, media_type TEXT, insert_time INTEGER)',
        );
      },
    );
  }

  /// 儲存 API 資料到快取，並嚴格執行 FIFO (最多 10 筆)
  Future<void> saveToCache(NasaApiData data) async {
    final db = await database;

    await db.insert(
      'cache',
      {
        ...data.toJson(),
        'insert_time': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.execute('''
      DELETE FROM cache 
      WHERE date NOT IN (
        SELECT date FROM cache 
        ORDER BY insert_time DESC 
        LIMIT 10
      )
    ''');
  }

  /// 取得「指定日期」的快取 (如果使用者離線時，剛好查了昨天查過的日期)
  Future<NasaApiData?> getCacheByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        'cache',
        where: 'date = ?',
        whereArgs: [date]
    );
    if (maps.isNotEmpty) return NasaApiData.fromJson(maps.first);
    return null;
  }

  /// 取得「最近一次」的快取 (當作最後的備援方案)
  Future<NasaApiData?> getLatestCache() async {
    final db = await database;
    // 依照寫入時間反向排序，只拿第一筆
    final List<Map<String, dynamic>> maps = await db.query(
        'cache',
        orderBy: 'insert_time DESC',
        limit: 1
    );
    if (maps.isNotEmpty) return NasaApiData.fromJson(maps.first);
    return null;
  }


  /// 儲存收藏
  Future<void> saveFavorite(NasaApiData data) async {
    final db = await database;
    await db.insert(
      'favorites',
      data.toJson(),
      // 如果日期重複，則替換舊資料 (ConflictAlgorithm.replace)
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    updateNotifier.value = !updateNotifier.value;
  }

  /// 取得所有收藏
  Future<List<NasaApiData>> getAllFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');

    return List.generate(maps.length, (i) {
      return NasaApiData.fromJson(maps[i]);
    });
  }

  /// 刪除收藏
  Future<void> deleteFavorite(String date) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'date = ?',
      whereArgs: [date],
    );
    updateNotifier.value = !updateNotifier.value;
  }

  /// 檢查是否已收藏
  Future<bool> isFavorite(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.isNotEmpty;
  }
}