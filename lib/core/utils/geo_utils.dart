
import 'dart:math';

class GeoUtils {
  static const double _earthRadius = 6371000.0;

  
  static double haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
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
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dl = _toRad(lon2 - lon1);
    final la1 = _toRad(lat1);
    final la2 = _toRad(lat2);
    final x = sin(dl) * cos(la2);
    final y = cos(la1) * sin(la2) - sin(la1) * cos(la2) * cos(dl);
    return (degrees(atan2(x, y)) + 360) % 360;
  }

  
  static String pointKey(double lat, double lon, {int precision = 5}) {
    final la = (lat * pow(10, precision)).round();
    final lo = (lon * pow(10, precision)).round();
    return '${la}_$lo';
  }

  static double _toRad(double deg) => deg * pi / 180;
  static double degrees(double rad) => rad * 180 / pi;
}
