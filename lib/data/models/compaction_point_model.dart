
import 'dart:convert';
import '../../domain/entities/compaction_point.dart';

class CompactionPointModel extends CompactionPoint {
  const CompactionPointModel({
    required super.pointId,
    required super.latitude,
    required super.longitude,
    required super.passes,
    required super.moistureField,
    required super.compactionPercent,
    required super.statusType,
    required super.accuracyM,
    required super.timestamp,
  });

  factory CompactionPointModel.fromEntity(CompactionPoint e) =>
      CompactionPointModel(
        pointId: e.pointId, latitude: e.latitude, longitude: e.longitude,
        passes: e.passes, moistureField: e.moistureField,
        compactionPercent: e.compactionPercent, statusType: e.statusType,
        accuracyM: e.accuracyM, timestamp: e.timestamp,
      );

  Map<String, dynamic> toJson() => {
    'pointId': pointId, 'latitude': latitude, 'longitude': longitude,
    'passes': passes, 'moistureField': moistureField,
    'compactionPercent': compactionPercent, 'statusType': statusType,
    'accuracyM': accuracyM, 'timestamp': timestamp.toIso8601String(),
  };

  factory CompactionPointModel.fromJson(Map<String, dynamic> j) =>
      CompactionPointModel(
        pointId: j['pointId'], latitude: j['latitude'], longitude: j['longitude'],
        passes: j['passes'], moistureField: j['moistureField'],
        compactionPercent: j['compactionPercent'], statusType: j['statusType'],
        accuracyM: j['accuracyM'], timestamp: DateTime.parse(j['timestamp']),
      );

  static String listToJson(List<CompactionPoint> points) =>
      jsonEncode(points.map((p) => CompactionPointModel.fromEntity(p).toJson()).toList());

  static List<CompactionPointModel> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((j) => CompactionPointModel.fromJson(j as Map<String,dynamic>)).toList();
  }
}
