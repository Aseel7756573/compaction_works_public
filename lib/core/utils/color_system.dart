
import 'package:flutter/material.dart';

enum CompactionStatus { critical, veryPoor, poor, marginal, fair, good, veryGood, excellent, ideal, overCompacted, severelyOverCompacted }

class CompactionRange {
  final double min;
  final double max;
  final Color color;
  final String label;
  final CompactionStatus status;

  const CompactionRange({
    required this.min,
    required this.max,
    required this.color,
    required this.label,
    required this.status,
  });
}

class CompactionColorSystem {
  static const List<CompactionRange> ranges = [
    CompactionRange(min: 0,   max: 60,  color: Color(0xFF67001F), label: 'خطر شديد < 60%',       status: CompactionStatus.critical),
    CompactionRange(min: 60,  max: 70,  color: Color(0xFFB2182B), label: 'ضعيف جداً 60-70%',      status: CompactionStatus.veryPoor),
    CompactionRange(min: 70,  max: 80,  color: Color(0xFFD6604D), label: 'ضعيف 70-80%',           status: CompactionStatus.poor),
    CompactionRange(min: 80,  max: 85,  color: Color(0xFFF4A582), label: 'مقبول بشرط 80-85%',     status: CompactionStatus.marginal),
    CompactionRange(min: 85,  max: 90,  color: Color(0xFFFDDBC7), label: 'متوسط 85-90%',          status: CompactionStatus.fair),
    CompactionRange(min: 90,  max: 93,  color: Color(0xFFD9EF8B), label: 'جيد 90-93%',            status: CompactionStatus.good),
    CompactionRange(min: 93,  max: 95,  color: Color(0xFFA6D96A), label: 'جيد جداً 93-95%',       status: CompactionStatus.veryGood),
    CompactionRange(min: 95,  max: 97,  color: Color(0xFF65BD63), label: 'ممتاز 95-97%',          status: CompactionStatus.excellent),
    CompactionRange(min: 97,  max: 100, color: Color(0xFF1A7837), label: 'مثالي 97-100%',         status: CompactionStatus.ideal),
    CompactionRange(min: 100, max: 103, color: Color(0xFF4393C3), label: 'دمك مفرط 100-103%',     status: CompactionStatus.overCompacted),
    CompactionRange(min: 103, max: 999, color: Color(0xFF2166AC), label: 'دمك مفرط شديد > 103%', status: CompactionStatus.severelyOverCompacted),
  ];

  static Color getColor(double value) {
    for (final r in ranges) {
      if (value >= r.min && value < r.max) return r.color;
    }
    return ranges.last.color;
  }

  static CompactionRange getRange(double value) {
    for (final r in ranges) {
      if (value >= r.min && value < r.max) return r;
    }
    return ranges.last;
  }

  static String getStatusText(double value, {double targetMin = 95, double targetMax = 100}) {
    if (value < targetMin) return '🔴 غير مقبول';
    if (value <= targetMax) return '🟢 مقبول';
    return '🔵 دمك مفرط';
  }

  static String getStatusType(double value, {double targetMin = 95, double targetMax = 100}) {
    if (value < targetMin) return 'poor';
    if (value <= targetMax) return 'good';
    return 'over';
  }

  
  static Color interpolateColor(double value) {
    value = value.clamp(60.0, 105.0);
    final normalized = (value - 60) / 45.0;

    final colors = [
      const Color(0xFF67001F),
      const Color(0xFFB2182B),
      const Color(0xFFD6604D),
      const Color(0xFFF4A582),
      const Color(0xFFD9EF8B),
      const Color(0xFFA6D96A),
      const Color(0xFF65BD63),
      const Color(0xFF1A7837),
      const Color(0xFF4393C3),
      const Color(0xFF2166AC),
    ];

    final index = (normalized * (colors.length - 1)).clamp(0.0, colors.length - 1.0);
    final lower = index.floor();
    final upper = index.ceil();
    final t = index - lower;

    if (lower == upper) return colors[lower];

    final c1 = colors[lower];
    final c2 = colors[upper];
    return Color.lerp(c1, c2, t)!;
  }
}
