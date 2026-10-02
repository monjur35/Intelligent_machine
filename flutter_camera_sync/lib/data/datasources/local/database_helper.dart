import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/batch_image_model.dart';
import '../../models/batch_model.dart';

class DatabaseHelper {
  static const _dbName = 'aerosync_batches.db';
  static const _dbVersion = 1;

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE batch_images (
        id TEXT PRIMARY KEY,
        batch_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        file_size_bytes INTEGER NOT NULL,
        captured_at TEXT NOT NULL,
        is_uploaded INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (batch_id) REFERENCES batches (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> insertBatch(BatchModel batch) async {
    final db = await database;
    await db.insert('batches', batch.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBatch(BatchModel batch) async {
    final db = await database;
    await db.update(
      'batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<void> insertImage(BatchImageModel image) async {
    final db = await database;
    await db.insert('batch_images', image.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BatchModel>> getBatches({bool onlyWithImages = true}) async {
    final db = await database;
    final batchRows =
        await db.query('batches', orderBy: 'created_at DESC');

    final List<BatchModel> result = [];
    for (final row in batchRows) {
      final batchId = row['id'] as String;
      final imageRows = await db.query(
        'batch_images',
        where: 'batch_id = ?',
        whereArgs: [batchId],
        orderBy: 'captured_at ASC',
      );

      final images = imageRows.map(BatchImageModel.fromMap).toList();
      if (!onlyWithImages || images.isNotEmpty) {
        result.add(BatchModel.fromMap(row, images));
      }
    }
    return result;
  }

  Future<BatchModel?> getBatch(String id) async {
    final db = await database;
    final batchRows =
        await db.query('batches', where: 'id = ?', whereArgs: [id]);
    if (batchRows.isEmpty) return null;

    final imageRows = await db.query(
      'batch_images',
      where: 'batch_id = ?',
      whereArgs: [id],
    );
    final images = imageRows.map(BatchImageModel.fromMap).toList();
    return BatchModel.fromMap(batchRows.first, images);
  }

  Future<void> deleteBatch(String id) async {
    final db = await database;
    await db.delete('batch_images', where: 'batch_id = ?', whereArgs: [id]);
    await db.delete('batches', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEmptyBatches() async {
    final db = await database;
    await db.rawDelete('''
      DELETE FROM batches 
      WHERE id NOT IN (SELECT DISTINCT batch_id FROM batch_images)
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
