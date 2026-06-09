
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/utils/compaction_model.dart';
import '../../domain/entities/compaction_point.dart';
import '../models/compaction_point_model.dart';

class DatabaseHelper {
  static const _dbName = 'fma_pro.db';
  static const _dbVersion = 1;
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        project_id   TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        created_at   TEXT NOT NULL,
        location     TEXT,
        engineer     TEXT,
        supervisor   TEXT,
        contractor   TEXT,
        stage        TEXT,
        layer_no     INTEGER DEFAULT 1,
        unit_system  TEXT DEFAULT 'g/cm³',
        ref_json     TEXT,
        points_json  TEXT
      )
    ''');
  }

  Future<void> saveProject({
    required ProjectMeta meta,
    required CalibrationData calibration,
    required List<CompactionPoint> points,
    required String unitSystem,
  }) async {
    final db = await database;
    await db.insert(
      'projects',
      {
        'project_id':  meta.projectId,
        'name':        meta.name,
        'created_at':  meta.createdAt.toIso8601String(),
        'location':    meta.location,
        'engineer':    meta.engineer,
        'supervisor':  meta.supervisor,
        'contractor':  meta.contractor,
        'stage':       meta.stage,
        'layer_no':    meta.layerNo,
        'unit_system': unitSystem,
        'ref_json':    jsonEncode(calibration.toJson()),
        'points_json': CompactionPointModel.listToJson(points),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProjectMeta>> getAllProjects() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'created_at DESC');
    return rows.map((r) => ProjectMeta.fromJson({
      'projectId': r['project_id'], 'name': r['name'],
      'location': r['location'] ?? '', 'engineer': r['engineer'] ?? '',
      'supervisor': r['supervisor'] ?? '', 'contractor': r['contractor'] ?? '',
      'stage': r['stage'] ?? '', 'layerNo': r['layer_no'] ?? 1,
      'createdAt': r['created_at'],
    })).toList();
  }

  Future<({CalibrationData? calibration, List<CompactionPoint> points})?> loadProject(String projectId) async {
    final db = await database;
    final rows = await db.query('projects', where: 'project_id = ?', whereArgs: [projectId]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final calibration = row['ref_json'] != null
        ? CalibrationData.fromJson(jsonDecode(row['ref_json'] as String))
        : null;
    final points = row['points_json'] != null
        ? CompactionPointModel.listFromJson(row['points_json'] as String)
        : <CompactionPoint>[];
    return (calibration: calibration, points: points);
  }

  Future<void> deleteProject(String projectId) async {
    final db = await database;
    await db.delete('projects', where: 'project_id = ?', whereArgs: [projectId]);
  }
}
