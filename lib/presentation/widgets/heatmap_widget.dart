import 'dart:math';


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/color_system.dart';
import '../../domain/entities/compaction_point.dart';
import '../theme/app_theme.dart';

class HeatmapWidget extends StatefulWidget {
  final List<CompactionPoint> points;
  final double? refLat;
  final double? refLon;
  final double northDeg;

  const HeatmapWidget({
    super.key,
    required this.points,
    this.refLat,
    this.refLon,
    this.northDeg = 0,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  final MapController _mapCtrl = MapController();
  bool _satellite = false;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.map_outlined, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('لا توجد نقاط لعرضها', style: TextStyle(color: AppTheme.textSecondary)),
          ]),
        ),
      );
    }

    final center = _calculateCenter();

    return Container(
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 18,
            maxZoom: 22,
            minZoom: 5,
          ),
          children: [
            
            TileLayer(
              urlTemplate: _satellite
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fma.compaction',
            ),

            
            PolylineLayer(polylines: [
              Polyline(
                points: widget.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                color: Colors.white.withOpacity(0.4),
                strokeWidth: 2,
              ),
            ]),

            
            CircleLayer(circles: _buildHeatCircles()),

            
            MarkerLayer(markers: _buildMarkers()),

            
            if (widget.refLat != null && widget.refLon != null)
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(widget.refLat!, widget.refLon!),
                  width: 40, height: 40,
                  child: _buildRefMarker(),
                ),
              ]),
          ],
        ),

        
        Positioned(top: 12, left: 12, child: _buildControls()),

        
        Positioned(bottom: 16, left: 16, child: _buildNorthArrow()),

        
        Positioned(bottom: 16, right: 16, child: _buildMiniLegend()),
      ]),
    );
  }

  List<CircleMarker> _buildHeatCircles() {
    return widget.points.map((p) {
      final color = CompactionColorSystem.getColor(p.compactionPercent);
      return CircleMarker(
        point: LatLng(p.latitude, p.longitude),
        radius: 18,
        color: color.withOpacity(0.35),
        borderColor: color.withOpacity(0.6),
        borderStrokeWidth: 1,
        useRadiusInMeter: false,
      );
    }).toList();
  }

  List<Marker> _buildMarkers() {
    return widget.points.map((p) {
      final color = CompactionColorSystem.getColor(p.compactionPercent);
      return Marker(
        point: LatLng(p.latitude, p.longitude),
        width: 32, height: 32,
        child: GestureDetector(
          onTap: () => _showPointInfo(p),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
            ),
            child: Center(
              child: Text(
                p.compactionPercent.toStringAsFixed(0),
                style: const TextStyle(fontSize: 7, color: Colors.white,
                  fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRefMarker() => Container(
    decoration: BoxDecoration(
      color: Colors.amber,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 8)],
    ),
    child: const Icon(Icons.star, size: 20, color: Colors.white),
  );

  Widget _buildControls() => Column(mainAxisSize: MainAxisSize.min, children: [
    _mapBtn(Icons.add, () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1)),
    const SizedBox(height: 4),
    _mapBtn(Icons.remove, () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1)),
    const SizedBox(height: 4),
    _mapBtn(Icons.my_location, () => _mapCtrl.move(_calculateCenter(), 18)),
    const SizedBox(height: 4),
    GestureDetector(
      onTap: () => setState(() => _satellite = !_satellite),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.card.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _satellite ? AppTheme.primary : AppTheme.border),
        ),
        child: Icon(Icons.satellite_alt, size: 18,
          color: _satellite ? AppTheme.primary : AppTheme.textSecondary),
      ),
    ),
  ]);

  Widget _mapBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppTheme.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, size: 18, color: AppTheme.textPrimary),
    ),
  );

  Widget _buildNorthArrow() {
    return Transform.rotate(
      angle: widget.northDeg * pi / 180,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppTheme.card.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.navigation, size: 16, color: Colors.red),
          const Text('N', style: TextStyle(fontSize: 9, color: Colors.white,
            fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _buildMiniLegend() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppTheme.card.withOpacity(0.9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('معامل الدمك', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        _legendRow(const Color(0xFF67001F), '< 60%'),
        _legendRow(const Color(0xFFD6604D), '70-80%'),
        _legendRow(const Color(0xFFD9EF8B), '85-90%'),
        _legendRow(const Color(0xFF1A7837), '97-100% ✅'),
        _legendRow(const Color(0xFF4393C3), '> 100% ⚠️'),
      ],
    ),
  );

  Widget _legendRow(Color color, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textPrimary)),
    ]),
  );

  LatLng _calculateCenter() {
    if (widget.points.isEmpty) return const LatLng(15.0, 44.0);
    final avgLat = widget.points.map((p) => p.latitude).reduce((a, b) => a + b) / widget.points.length;
    final avgLon = widget.points.map((p) => p.longitude).reduce((a, b) => a + b) / widget.points.length;
    return LatLng(avgLat, avgLon);
  }

  void _showPointInfo(CompactionPoint p) {
    final color = CompactionColorSystem.getColor(p.compactionPercent);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 16, height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(p.pointId, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(CompactionColorSystem.getStatusText(p.compactionPercent),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
            const Divider(height: 20),
            _infoRow('معامل الدمك', '${p.compactionPercent.toStringAsFixed(2)}%'),
            _infoRow('عدد الدورات', p.passes.toString()),
            _infoRow('الرطوبة الحقلية', '${p.moistureField.toStringAsFixed(1)}%'),
            _infoRow('دقة GPS', '${p.accuracyM.toStringAsFixed(1)} م'),
            _infoRow('خط العرض', p.latitude.toStringAsFixed(7)),
            _infoRow('خط الطول', p.longitude.toStringAsFixed(7)),
            _infoRow('الوقت', '${p.timestamp.hour}:${p.timestamp.minute.toString().padLeft(2,'0')}:${p.timestamp.second.toString().padLeft(2,'0')}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary,
        fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}
