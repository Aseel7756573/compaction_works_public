
import '../../core/utils/compaction_model.dart';
import '../../core/utils/unit_system.dart';
import '../../domain/entities/compaction_point.dart';
import '../../domain/repositories/export_repository.dart';
import '../datasources/export_datasource.dart';

class ExportRepositoryImpl implements ExportRepository {
  final ExportDatasource _ds;
  ExportRepositoryImpl(this._ds);

  @override
  Future<String> exportExcel({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  }) =>
      _ds.exportExcel(
        points: points,
        calibration: calibration,
        meta: meta,
        unitSystem: unitSystem,
      );

  @override
  Future<String> exportPdf({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  }) =>
      _ds.exportPdf(
        points: points,
        calibration: calibration,
        meta: meta,
        unitSystem: unitSystem,
      );
}
