
import 'package:equatable/equatable.dart';

class CompactionPoint extends Equatable {
  final String pointId;
  final double latitude;
  final double longitude;
  final int passes;
  final double moistureField;
  final double compactionPercent;
  final String statusType;     
  final double accuracyM;
  final DateTime timestamp;

  const CompactionPoint({
    required this.pointId,
    required this.latitude,
    required this.longitude,
    required this.passes,
    required this.moistureField,
    required this.compactionPercent,
    required this.statusType,
    required this.accuracyM,
    required this.timestamp,
  });

  CompactionPoint copyWith({int? passes, double? compactionPercent, String? statusType}) {
    return CompactionPoint(
      pointId: pointId,
      latitude: latitude,
      longitude: longitude,
      passes: passes ?? this.passes,
      moistureField: moistureField,
      compactionPercent: compactionPercent ?? this.compactionPercent,
      statusType: statusType ?? this.statusType,
      accuracyM: accuracyM,
      timestamp: timestamp,
    );
  }

  @override
  List<Object?> get props => [pointId, latitude, longitude, passes, compactionPercent];
}


class ProjectMeta extends Equatable {
  final String projectId;
  final String name;
  final String location;
  final String engineer;
  final String supervisor;
  final String contractor;
  final String stage;
  final int layerNo;
  final DateTime createdAt;

  const ProjectMeta({
    required this.projectId,
    required this.name,
    required this.location,
    required this.engineer,
    required this.supervisor,
    required this.contractor,
    required this.stage,
    required this.layerNo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId, 'name': name, 'location': location,
    'engineer': engineer, 'supervisor': supervisor, 'contractor': contractor,
    'stage': stage, 'layerNo': layerNo,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProjectMeta.fromJson(Map<String, dynamic> j) => ProjectMeta(
    projectId: j['projectId'], name: j['name'], location: j['location'],
    engineer: j['engineer'], supervisor: j['supervisor'], contractor: j['contractor'],
    stage: j['stage'], layerNo: j['layerNo'],
    createdAt: DateTime.parse(j['createdAt']),
  );

  @override
  List<Object?> get props => [projectId];
}


class CompactionStats {
  final int total;
  final int goodCount;
  final int poorCount;
  final int overCount;
  final double average;
  final double max;
  final double min;
  final double stdDev;
  final double cv; 

  const CompactionStats({
    required this.total,
    required this.goodCount,
    required this.poorCount,
    required this.overCount,
    required this.average,
    required this.max,
    required this.min,
    required this.stdDev,
    required this.cv,
  });

  double get passRate => total > 0 ? goodCount / total * 100 : 0;

  static CompactionStats fromPoints(List<CompactionPoint> points) {
    if (points.isEmpty) {
      return const CompactionStats(total:0,goodCount:0,poorCount:0,overCount:0,average:0,max:0,min:0,stdDev:0,cv:0);
    }
    final vals = points.map((p) => p.compactionPercent).toList();
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final mx  = vals.reduce((a, b) => a > b ? a : b);
    final mn  = vals.reduce((a, b) => a < b ? a : b);
    final variance = vals.map((v) => (v - avg) * (v - avg)).reduce((a,b)=>a+b) / vals.length;
    final std = variance > 0 ? variance.sqrtVal() : 0.0;
    return CompactionStats(
      total: points.length,
      goodCount: points.where((p) => p.statusType == 'good').length,
      poorCount: points.where((p) => p.statusType == 'poor').length,
      overCount: points.where((p) => p.statusType == 'over').length,
      average: avg, max: mx, min: mn, stdDev: std,
      cv: avg > 0 ? std / avg * 100 : 0,
    );
  }
}

extension _DoubleExt on double {
  double sqrtVal() {
    double x = this;
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 50; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
