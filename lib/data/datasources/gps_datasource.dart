
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/kalman_filter.dart';
import '../../core/error/failures.dart';

class GpsReading {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const GpsReading({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });
}

class GpsDatasource {
  final GpsKalmanFilter _kalman = GpsKalmanFilter();
  StreamSubscription<Position>? _subscription;
  final StreamController<GpsReading> _controller = StreamController.broadcast();

  Stream<GpsReading> get positionStream => _controller.stream;

  Future<void> requestPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      throw const PermissionFailure('تم رفض إذن الموقع. يرجى تفعيله من الإعدادات.');
    }
    
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const GpsFailure('خدمة GPS غير مفعّلة. يرجى تفعيلها من إعدادات الهاتف.');
    }
  }

  Future<GpsReading> getCurrentPosition() async {
    await requestPermission();
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 15),
    );
    final filtered = _kalman.update(pos.latitude, pos.longitude, pos.accuracy);
    return GpsReading(
      latitude: filtered.lat,
      longitude: filtered.lon,
      accuracy: pos.accuracy,
      timestamp: DateTime.now(),
    );
  }

  void startTracking({double distanceFilter = 0}) {
    _kalman.reset();
    _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilter.toInt(),
        intervalDuration: const Duration(milliseconds: 500),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'FMA يتتبع موقعك للدمك الذكي',
          notificationTitle: 'تتبع الدمك نشط',
          enableWakeLock: true,
        ),
      ),
    ).listen(
      (pos) {
        final filtered = _kalman.update(pos.latitude, pos.longitude, pos.accuracy);
        _controller.add(GpsReading(
          latitude: filtered.lat,
          longitude: filtered.lon,
          accuracy: pos.accuracy,
          timestamp: DateTime.now(),
        ));
      },
      onError: (e) => _controller.addError(GpsFailure(e.toString())),
    );
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _kalman.reset();
  }

  void dispose() {
    stopTracking();
    _controller.close();
  }
}
