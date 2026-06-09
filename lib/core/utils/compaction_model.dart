
import 'dart:math';




class CompactionModel {
  final CalibrationData calibration;

  late final double _eRef;
  late final double _deltaCRef;
  late final double _sigmaW;
  late final double _cMin;

  static const double cMaxAllowed = 105.0;

  static const Map<String, double> _soilFactors = {
    'رملية': 1.00,
    'رملية طينية': 0.97,
    'غرينية': 0.95,
    'طينية': 0.92,
    'صخرية مكسرة': 1.05,
  };

  CompactionModel(this.calibration) {
    _calibrate();
  }

  void _calibrate() {
    final eff = calibration.equipmentEfficiency;
    _eRef = log(calibration.refPasses * eff + 1);
    _deltaCRef = calibration.finalCompaction - calibration.initialCompaction;
    _cMin = calibration.initialCompaction;

    
    final wDiffBefore = (calibration.moistureBefore - calibration.omc).abs();
    final ratio = calibration.initialCompaction / calibration.finalCompaction.clamp(1.0, 200.0);

    if (wDiffBefore > 0.1 && ratio > 0.01 && ratio < 1.0) {
      _sigmaW = (wDiffBefore / sqrt(-2 * log(ratio))).clamp(1.5, 8.0);
    } else {
      _sigmaW = 3.0;
    }
  }

  
  double predict(int passes, double moistureField) {
    if (passes <= 0) return _cMin;

    final eff = calibration.equipmentEfficiency;

    
    final eCurrent = log(passes * eff + 1);
    final energyRatio = eCurrent / _eRef.clamp(1e-6, double.infinity);

    
    final wDev = moistureField - calibration.omc;
    final mW = exp(-(wDev * wDev) / (2 * _sigmaW * _sigmaW)).clamp(0.50, 1.0);

    
    final soilFactor = _soilFactors[calibration.soilType] ?? 1.0;

    final c = _cMin + _deltaCRef * energyRatio * mW * soilFactor;
    return c.clamp(0.0, cMaxAllowed).roundToDecimalPlaces(2);
  }

  
  static double fromDensities(double fieldDensity, double maxDryDensity) {
    return ((fieldDensity / maxDryDensity) * 100).roundToDecimalPlaces(2);
  }
}

extension DoubleRound on double {
  double roundToDecimalPlaces(int places) {
    final factor = pow(10, places).toDouble();
    return (this * factor).round() / factor;
  }
}




class CalibrationData {
  final double refLat;
  final double refLon;
  final double maxDryDensityGcm3;   
  final double omc;                  
  final String soilType;
  final double initialCompaction;    
  final int refPasses;
  final double finalCompaction;      
  final double moistureBefore;       
  final double moistureAfter;        
  final double equipmentEfficiency;  
  final double targetMin;            
  final double targetMax;            

  const CalibrationData({
    required this.refLat,
    required this.refLon,
    required this.maxDryDensityGcm3,
    required this.omc,
    required this.soilType,
    required this.initialCompaction,
    required this.refPasses,
    required this.finalCompaction,
    required this.moistureBefore,
    required this.moistureAfter,
    required this.equipmentEfficiency,
    this.targetMin = 95.0,
    this.targetMax = 100.0,
  });

  Map<String, dynamic> toJson() => {
    'refLat': refLat, 'refLon': refLon,
    'maxDryDensityGcm3': maxDryDensityGcm3, 'omc': omc,
    'soilType': soilType, 'initialCompaction': initialCompaction,
    'refPasses': refPasses, 'finalCompaction': finalCompaction,
    'moistureBefore': moistureBefore, 'moistureAfter': moistureAfter,
    'equipmentEfficiency': equipmentEfficiency,
    'targetMin': targetMin, 'targetMax': targetMax,
  };

  factory CalibrationData.fromJson(Map<String, dynamic> j) => CalibrationData(
    refLat: j['refLat'], refLon: j['refLon'],
    maxDryDensityGcm3: j['maxDryDensityGcm3'], omc: j['omc'],
    soilType: j['soilType'], initialCompaction: j['initialCompaction'],
    refPasses: j['refPasses'], finalCompaction: j['finalCompaction'],
    moistureBefore: j['moistureBefore'], moistureAfter: j['moistureAfter'],
    equipmentEfficiency: j['equipmentEfficiency'],
    targetMin: j['targetMin'] ?? 95.0, targetMax: j['targetMax'] ?? 100.0,
  );
}
