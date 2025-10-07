import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:fms/core/models/geo.dart';

class FlutterMapWidget extends StatelessWidget {
  final GeoPoint center;
  final double zoom;
  final List<MapMarkerModel> markers;
  final List<MapZoneModel> zones;
  final void Function(MapMarkerModel marker)? onMarkerTap;
  const FlutterMapWidget({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.zones = const [],
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    final worldBounds = LatLngBounds(
      ll.LatLng(-85.0511, -180.0),
      ll.LatLng(85.0511, 180.0),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: ll.LatLng(center.lat, center.lng),
          initialZoom: zoom,
          cameraConstraint: CameraConstraint.contain(bounds: worldBounds),
          maxZoom: 15
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.quetra.fms',
            maxZoom: 15,
          ),
          if (zones.isNotEmpty)
            PolygonLayer(
              polygons: zones
                  .where((z) => z.type == MapZoneType.polygon)
                  .map(
                    (zone) {
                      final fillColor = _parseColor(
                            zone.style?.fillColorHex,
                            zone.style?.fillOpacity,
                          ) ??
                          Colors.blue.withOpacity(0.2);
                      final borderColor = _parseColor(
                            zone.style?.strokeColorHex,
                            zone.style?.strokeOpacity,
                          ) ??
                          Colors.blue;
                      return Polygon(
                        points: zone.points
                            .map((p) => ll.LatLng(p.lat, p.lng))
                            .toList(),
                        color: fillColor,
                        borderColor: borderColor,
                        borderStrokeWidth: (zone.style?.strokeWidth ?? 2).toDouble(),
                      );
                    },
                  )
                  .toList(),
            ),
          if (zones.any((z) => z.type == MapZoneType.polyline))
            PolylineLayer(
              polylines: zones
                  .where((z) => z.type == MapZoneType.polyline)
                  .map(
                    (zone) {
                      final strokeColor = _parseColor(
                            zone.style?.strokeColorHex,
                            zone.style?.strokeOpacity,
                          ) ??
                          Colors.blue;
                      return Polyline(
                        points: zone.points
                            .map((p) => ll.LatLng(p.lat, p.lng))
                            .toList(),
                        color: strokeColor,
                        strokeWidth: (zone.style?.strokeWidth ?? 2).toDouble(),
                      );
                    },
                  )
                  .toList(),
            ),
          MarkerLayer(
            markers: markers
                .map(
                  (m) => Marker(
                    point: ll.LatLng(m.position.lat, m.position.lng),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: onMarkerTap != null ? () => onMarkerTap!(m) : null,
                      child: Tooltip(
                        message: _buildTooltipMessage(m),
                        child: _buildMarkerIcon(m),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _buildTooltipMessage(MapMarkerModel marker) {
    final parts = <String>[];
    if (marker.title != null && marker.title!.isNotEmpty) {
      parts.add(marker.title!);
    }
    if (marker.subtitle != null && marker.subtitle!.isNotEmpty) {
      parts.add(marker.subtitle!);
    }
    return parts.join('\n');
  }

  Widget _buildMarkerIcon(MapMarkerModel marker) {
    if (marker.iconUrl != null && marker.iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          marker.iconUrl!,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 30,
          ),
        ),
      );
    }
    return const Icon(
      Icons.location_pin,
      color: Colors.red,
      size: 30,
    );
  }

  Color? _parseColor(String? hex, double? opacity) {
    if (hex == null || hex.isEmpty) {
      return null;
    }
    var formatted = hex.replaceAll('#', '');
    if (formatted.length == 3) {
      formatted = formatted.split('').map((c) => '$c$c').join();
    }
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    if (formatted.length != 8) {
      return null;
    }
    final value = int.tryParse(formatted, radix: 16);
    if (value == null) {
      return null;
    }
    final color = Color(value);
    if (opacity != null) {
      return color.withOpacity(opacity.clamp(0, 1));
    }
    return color;
  }
}
