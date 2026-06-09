
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/compaction_model.dart';
import '../../core/utils/unit_system.dart';
import '../../domain/entities/compaction_point.dart';
import '../../domain/repositories/export_repository.dart';


abstract class ExportState extends Equatable {
  const ExportState();
}

class ExportIdle extends ExportState {
  @override
  List<Object?> get props => [];
}

class ExportLoading extends ExportState {
  final String message;
  const ExportLoading(this.message);
  @override
  List<Object?> get props => [message];
}

class ExportSuccess extends ExportState {
  final String path;
  final String type;
  const ExportSuccess({required this.path, required this.type});
  @override
  List<Object?> get props => [path];
}

class ExportError extends ExportState {
  final String message;
  const ExportError(this.message);
  @override
  List<Object?> get props => [message];
}


class ExportCubit extends Cubit<ExportState> {
  final ExportRepository _repo;
  ExportCubit(this._repo) : super(ExportIdle());

  Future<void> exportExcel({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  }) async {
    emit(const ExportLoading('جاري تجهيز ملف Excel...'));
    try {
      final path = await _repo.exportExcel(
        points: points,
        calibration: calibration,
        meta: meta,
        unitSystem: unitSystem,
      );
      emit(ExportSuccess(path: path, type: 'excel'));
      await Share.shareXFiles([XFile(path)], text: 'تقرير FMA - ${meta.name}');
    } catch (e) {
      emit(ExportError(e.toString()));
    } finally {
      emit(ExportIdle());
    }
  }

  Future<void> exportPdf({
    required List<CompactionPoint> points,
    required CalibrationData calibration,
    required ProjectMeta meta,
    required UnitSystem unitSystem,
  }) async {
    emit(const ExportLoading('جاري تجهيز تقرير PDF...'));
    try {
      final path = await _repo.exportPdf(
        points: points,
        calibration: calibration,
        meta: meta,
        unitSystem: unitSystem,
      );
      emit(ExportSuccess(path: path, type: 'pdf'));
      await Share.shareXFiles([XFile(path)], text: 'تقرير FMA - ${meta.name}');
    } catch (e) {
      emit(ExportError(e.toString()));
    } finally {
      emit(ExportIdle());
    }
  }
}
