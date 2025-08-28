class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

class MapMarkerModel {
  final String id;
  final GeoPoint position;
  final String? title;
  const MapMarkerModel({required this.id, required this.position, this.title});
}
