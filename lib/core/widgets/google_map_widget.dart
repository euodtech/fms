import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fms/core/models/geo.dart';

class GoogleMapWidget extends StatefulWidget {
  final GeoPoint center;
  final double zoom;
  final List<MapMarkerModel> markers;
  const GoogleMapWidget({super.key, required this.center, this.zoom = 14, this.markers = const []});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final markerSet = widget.markers
        .map((m) => Marker(
              markerId: MarkerId(m.id),
              position: LatLng(m.position.lat, m.position.lng),
              infoWindow: InfoWindow(title: m.title),
            ))
        .toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(widget.center.lat, widget.center.lng), zoom: widget.zoom),
        markers: markerSet,
        onMapCreated: (c) => _controller = c,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}
