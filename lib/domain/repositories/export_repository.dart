
import '../entities/compaction_point.dart';
import '../../core/utils/compaction_model.dart';
import '../../core/utils/unit_system.dart';

abstract class ExportRepository {
  Future<String> exportExcel({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  });

  Future<String> exportPdf({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  });
}
