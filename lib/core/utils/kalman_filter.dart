
import 'dart:math';


class GpsKalmanFilter {
  final double processNoise;
  final double measurementNoise;

  double _p = 1.0;
  double? _lat;
  double? _lon;

  GpsKalmanFilter({
    this.processNoise = 1e-5,
    this.measurementNoise = 1e-4,
  });

  
  
  ({double lat, double lon}) update(double lat, double lon, double accuracy) {
    final rAdj = measurementNoise * (1 + accuracy / 10.0);

    if (_lat == null) {
      _lat = lat;
      _lon = lon;
      return (lat: lat, lon: lon);
    }

    
    _p += processNoise;

    
    final k = _p / (_p + rAdj);

    
    _lat = _lat! + k * (lat - _lat!);
    _lon = _lon! + k * (lon - _lon!);
    _p *= (1 - k);

    return (lat: _lat!, lon: _lon!);
  }

  void reset() {
    _lat = null;
    _lon = null;
    _p = 1.0;
  }
}


class GeoUtils {
  static const double _earthRadius = 6371000.0;

  
  static double haversine(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final p1 = _toRad(lat1);
    final p2 = _toRad(lat2);
    final dp = _toRad(lat2 - lat1);
    final dl = _toRad(lon2 - lon1);

    final a = sin(dp / 2) * sin(dp / 2) +
        cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2);
    return _earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  
  static double bearing(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dl = _toRad(lon2 - lon1);
    final la1 = _toRad(lat1);
    final la2 = _toRad(lat2);
    final x = sin(dl) * cos(la2);
    final y = cos(la1) * sin(la2) - sin(la1) * cos(la2) * cos(dl);
    return (degrees(atan2(x, y)) + 360) % 360;
  }

  static double _toRad(double deg) => deg * pi / 180;
  static double degrees(double rad) => rad * 180 / pi;

  
  static String pointKey(double lat, double lon, {int precision = 5}) {
    final la = (lat * pow(10, precision)).round();
    final lo = (lon * pow(10, precision)).round();
    return '${la}_$lo';
  }
}
