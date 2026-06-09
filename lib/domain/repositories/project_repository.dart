
import '../entities/compaction_point.dart';
import '../../core/utils/compaction_model.dart';

abstract class ProjectRepository {
  Future<void> saveProject({
    required ProjectMeta meta,
    required CalibrationData calibration,
    required List<CompactionPoint> points,
    required String unitSystem,
  });

  Future<List<ProjectMeta>> getAllProjects();

  Future<({CalibrationData? calibration, List<CompactionPoint> points})?> loadProject(String projectId);

  Future<void> deleteProject(String projectId);
}
