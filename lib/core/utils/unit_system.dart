

enum DensityUnit { gcm3, kgm3, knm3, pcf }
enum LengthUnit { metric, imperial }

class UnitSystem {
  final DensityUnit densityUnit;
  final LengthUnit lengthUnit;

  const UnitSystem({
    this.densityUnit = DensityUnit.gcm3,
    this.lengthUnit = LengthUnit.metric,
  });

  
  static const Map<DensityUnit, double> _densityFactors = {
    DensityUnit.gcm3: 1.0,
    DensityUnit.kgm3: 1000.0,
    DensityUnit.knm3: 9.80665,
    DensityUnit.pcf: 62.42796,
  };

  static const Map<DensityUnit, String> _densityLabels = {
    DensityUnit.gcm3: 'g/cm³',
    DensityUnit.kgm3: 'kg/m³',
    DensityUnit.knm3: 'kN/m³',
    DensityUnit.pcf: 'lb/ft³',
  };

  static const Map<DensityUnit, (double, double)> _densityRanges = {
    DensityUnit.gcm3: (1.4, 2.2),
    DensityUnit.kgm3: (1400, 2200),
    DensityUnit.knm3: (13.7, 21.6),
    DensityUnit.pcf: (87.4, 137.3),
  };

  
  double densityToSI(double value) => value / _densityFactors[densityUnit]!;
  double densityFromSI(double gcm3) => gcm3 * _densityFactors[densityUnit]!;

  String get densityLabel => _densityLabels[densityUnit]!;
  (double, double) get densityRange => _densityRanges[densityUnit]!;

  String formatDensity(double gcm3, {int decimals = 3}) {
    return '${densityFromSI(gcm3).toStringAsFixed(decimals)} $densityLabel';
  }

  
  double lengthToMeters(double value) =>
      lengthUnit == LengthUnit.metric ? value : value * 0.3048;

  double lengthFromMeters(double meters) =>
      lengthUnit == LengthUnit.metric ? meters : meters / 0.3048;

  String get lengthLabel => lengthUnit == LengthUnit.metric ? 'm' : 'ft';

  String formatLength(double meters) {
    final v = lengthFromMeters(meters);
    return '${v.toStringAsFixed(1)} $lengthLabel';
  }

  UnitSystem copyWith({DensityUnit? densityUnit, LengthUnit? lengthUnit}) {
    return UnitSystem(
      densityUnit: densityUnit ?? this.densityUnit,
      lengthUnit: lengthUnit ?? this.lengthUnit,
    );
  }
}
