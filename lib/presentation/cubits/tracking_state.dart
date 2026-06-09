
part of 'tracking_cubit.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();
}

class TrackingInitial extends TrackingState {
  @override List<Object?> get props => [];
}

class TrackingError extends TrackingState {
  final String message;
  const TrackingError({required this.message});
  @override List<Object?> get props => [message];
}

class TrackingReady extends TrackingState {
  final CalibrationData calibration;
  final List<CompactionPoint> points;
  final UnitSystem unitSystem;
  final double northDeg;
  final double spacingM;
  final double minAccuracy;

  const TrackingReady({
    required this.calibration,
    required this.points,
    required this.unitSystem,
    required this.northDeg,
    required this.spacingM,
    required this.minAccuracy,
  });

  TrackingReady copyWithSettings({
    UnitSystem? unitSystem,
    double? northDeg,
    double? spacingM,
    double? minAccuracy,
    List<CompactionPoint>? points,
  }) => TrackingReady(
    calibration: calibration,
    points: points ?? this.points,
    unitSystem: unitSystem ?? this.unitSystem,
    northDeg: northDeg ?? this.northDeg,
    spacingM: spacingM ?? this.spacingM,
    minAccuracy: minAccuracy ?? this.minAccuracy,
  );

  @override
  List<Object?> get props => [calibration, points.length, unitSystem.densityUnit, northDeg, spacingM];
}

class TrackingActive extends TrackingState {
  final CalibrationData calibration;
  final List<CompactionPoint> points;
  final double currentLat;
  final double currentLon;
  final double currentAcc;
  final UnitSystem unitSystem;
  final double northDeg;
  final double spacingM;
  final double minAccuracy;

  const TrackingActive({
    required this.calibration,
    required this.points,
    required this.currentLat,
    required this.currentLon,
    required this.currentAcc,
    required this.unitSystem,
    required this.northDeg,
    required this.spacingM,
    required this.minAccuracy,
  });

  TrackingActive copyWithGps({required double lat, required double lon, required double acc}) =>
    TrackingActive(
      calibration: calibration, points: points,
      currentLat: lat, currentLon: lon, currentAcc: acc,
      unitSystem: unitSystem, northDeg: northDeg,
      spacingM: spacingM, minAccuracy: minAccuracy,
    );

  TrackingActive copyWithPoints(List<CompactionPoint> newPoints) =>
    TrackingActive(
      calibration: calibration, points: newPoints,
      currentLat: currentLat, currentLon: currentLon, currentAcc: currentAcc,
      unitSystem: unitSystem, northDeg: northDeg,
      spacingM: spacingM, minAccuracy: minAccuracy,
    );

  @override
  List<Object?> get props => [points.length, currentLat, currentLon, currentAcc];
}
