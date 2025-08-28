import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:fms/core/models/geo.dart';

class FlutterMapWidget extends StatelessWidget {
  final GeoPoint center;
  final double zoom;
  final List<MapMarkerModel> markers;
  const FlutterMapWidget({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
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
          MarkerLayer(
            markers: markers
                .map(
                  (m) => Marker(
                    point: ll.LatLng(m.position.lat, m.position.lng),
                    width: 36,
                    height: 36,
                    child: Tooltip(
                      message: m.title ?? '',
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 30,
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
}
