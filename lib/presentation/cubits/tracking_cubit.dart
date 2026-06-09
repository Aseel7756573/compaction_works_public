
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/compaction_model.dart';
import '../../core/utils/color_system.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/unit_system.dart';
import '../../data/datasources/gps_datasource.dart';
import '../../domain/entities/compaction_point.dart';
import '../../domain/repositories/project_repository.dart';

part 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final GpsDatasource _gps;
  final ProjectRepository _projectRepo;

  StreamSubscription<GpsReading>? _gpsSub;
  CompactionModel? _model;
  final Map<String, int> _passesCount = {};
  (double, double)? _lastPos;
  final _uuid = const Uuid();

  TrackingCubit({
    required GpsDatasource gps,
    required ProjectRepository projectRepo,
  })  : _gps = gps,
        _projectRepo = projectRepo,
        super(TrackingInitial());

  
  
  
  void setCalibration(CalibrationData calibration) {
    _model = CompactionModel(calibration);
    emit(TrackingReady(
      calibration: calibration,
      points: [],
      unitSystem: _currentUnitSystem,
      northDeg: _currentNorthDeg,
      spacingM: _currentSpacingM,
      minAccuracy: _currentMinAcc,
    ));
  }

  
  
  
  void startTracking() {
    if (_model == null) return;
    final current = state;
    if (current is! TrackingReady) return;

    _passesCount.clear();
    _lastPos = null;

    emit(TrackingActive(
      calibration: current.calibration,
      points: [],
      currentLat: 0,
      currentLon: 0,
      currentAcc: 0,
      northDeg: current.northDeg,
      spacingM: current.spacingM,
      minAccuracy: current.minAccuracy,
      unitSystem: current.unitSystem,
    ));

    _gpsSub?.cancel();
    _gps.startTracking(distanceFilter: 1);
    _gpsSub = _gps.positionStream.listen(_onGpsReading, onError: _onGpsError);
  }

  void _onGpsReading(GpsReading reading) {
    final current = state;
    if (current is! TrackingActive) return;

    
    emit(current.copyWithGps(
      lat: reading.latitude,
      lon: reading.longitude,
      acc: reading.accuracy,
    ));

    
    if (reading.accuracy > current.minAccuracy) return;

    
    bool shouldRecord = _lastPos == null;
    if (_lastPos != null) {
      final dist = GeoUtils.haversine(
        _lastPos!.$1, _lastPos!.$2,
        reading.latitude, reading.longitude,
      );
      shouldRecord = dist >= current.spacingM;
    }

    if (!shouldRecord) return;

    
    final key = GeoUtils.pointKey(reading.latitude, reading.longitude);
    _passesCount[key] = (_passesCount[key] ?? 0) + 1;
    final passes = _passesCount[key]!;

    
    final moistureField = (current.calibration.moistureBefore + current.calibration.moistureAfter) / 2;

    
    final comp = _model!.predict(passes, moistureField);
    final statusType = CompactionColorSystem.getStatusType(
      comp,
      targetMin: current.calibration.targetMin,
      targetMax: current.calibration.targetMax,
    );
    final statusText = CompactionColorSystem.getStatusText(
      comp,
      targetMin: current.calibration.targetMin,
      targetMax: current.calibration.targetMax,
    );

    
    final existingIndex = current.points.indexWhere((p) =>
      GeoUtils.pointKey(p.latitude, p.longitude) == key);

    List<CompactionPoint> updatedPoints;
    if (existingIndex >= 0) {
      
      updatedPoints = List.from(current.points);
      updatedPoints[existingIndex] = updatedPoints[existingIndex].copyWith(
        passes: passes,
        compactionPercent: comp,
        statusType: statusType,
      );
    } else {
      
      final newPoint = CompactionPoint(
        pointId: 'P${(current.points.length + 1).toString().padLeft(4, '0')}',
        latitude: reading.latitude,
        longitude: reading.longitude,
        passes: passes,
        moistureField: moistureField,
        compactionPercent: comp,
        statusType: statusType,
        accuracyM: reading.accuracy,
        timestamp: DateTime.now(),
      );
      updatedPoints = [...current.points, newPoint];
      _lastPos = (reading.latitude, reading.longitude);
    }

    emit(current.copyWithPoints(updatedPoints));
  }

  void _onGpsError(Object error) {
    emit(TrackingError(message: error.toString()));
  }

  
  
  
  void stopTracking() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _gps.stopTracking();

    final current = state;
    if (current is TrackingActive) {
      emit(TrackingReady(
        calibration: current.calibration,
        points: current.points,
        unitSystem: current.unitSystem,
        northDeg: current.northDeg,
        spacingM: current.spacingM,
        minAccuracy: current.minAccuracy,
      ));
    }
  }

  
  
  
  void updateSettings({
    UnitSystem? unitSystem,
    double? northDeg,
    double? spacingM,
    double? minAccuracy,
  }) {
    final current = state;
    if (current is TrackingReady) {
      emit(current.copyWithSettings(
        unitSystem: unitSystem,
        northDeg: northDeg,
        spacingM: spacingM,
        minAccuracy: minAccuracy,
      ));
    }
  }

  
  
  
  Future<void> saveProject(ProjectMeta meta) async {
    final current = state;
    List<CompactionPoint> points = [];
    CalibrationData? calibration;

    if (current is TrackingReady) {
      points = current.points;
      calibration = current.calibration;
    } else if (current is TrackingActive) {
      points = current.points;
      calibration = current.calibration;
    }

    if (calibration == null || points.isEmpty) return;

    await _projectRepo.saveProject(
      meta: meta,
      calibration: calibration,
      points: points,
      unitSystem: _currentUnitSystem.densityLabel,
    );
  }

  
  
  
  Future<void> loadProject(String projectId) async {
    final result = await _projectRepo.loadProject(projectId);
    if (result == null || result.calibration == null) return;

    _model = CompactionModel(result.calibration!);
    emit(TrackingReady(
      calibration: result.calibration!,
      points: result.points,
      unitSystem: _currentUnitSystem,
      northDeg: _currentNorthDeg,
      spacingM: _currentSpacingM,
      minAccuracy: _currentMinAcc,
    ));
  }

  
  
  
  void clearPoints() {
    _passesCount.clear();
    _lastPos = null;
    final current = state;
    if (current is TrackingReady) {
      emit(current.copyWithSettings());
    }
  }

  
  UnitSystem get _currentUnitSystem {
    final s = state;
    if (s is TrackingReady) return s.unitSystem;
    if (s is TrackingActive) return s.unitSystem;
    return const UnitSystem();
  }

  double get _currentNorthDeg {
    final s = state;
    if (s is TrackingReady) return s.northDeg;
    if (s is TrackingActive) return s.northDeg;
    return 0.0;
  }

  double get _currentSpacingM {
    final s = state;
    if (s is TrackingReady) return s.spacingM;
    if (s is TrackingActive) return s.spacingM;
    return 5.0;
  }

  double get _currentMinAcc {
    final s = state;
    if (s is TrackingReady) return s.minAccuracy;
    if (s is TrackingActive) return s.minAccuracy;
    return 15.0;
  }

  @override
  Future<void> close() {
    _gpsSub?.cancel();
    _gps.dispose();
    return super.close();
  }
}
