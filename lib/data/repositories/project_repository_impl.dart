
import '../../core/utils/compaction_model.dart';
import '../../domain/entities/compaction_point.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/database_helper.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final DatabaseHelper _db;
  ProjectRepositoryImpl(this._db);

  @override
  Future<void> saveProject({
    required ProjectMeta meta,
    required CalibrationData calibration,
    required List<CompactionPoint> points,
    required String unitSystem,
  }) =>
      _db.saveProject(
        meta: meta,
        calibration: calibration,
        points: points,
        unitSystem: unitSystem,
      );

  @override
  Future<List<ProjectMeta>> getAllProjects() => _db.getAllProjects();

  @override
  Future<({CalibrationData? calibration, List<CompactionPoint> points})?> loadProject(
      String projectId) =>
      _db.loadProject(projectId);

  @override
  Future<void> deleteProject(String projectId) => _db.deleteProject(projectId);
}
