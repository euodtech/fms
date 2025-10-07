class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

class MapMarkerModel {
  final String id;
  final GeoPoint position;
  final String? title;
  final String? iconUrl;
  final String? subtitle;
  final Object? data;
  const MapMarkerModel({
    required this.id,
    required this.position,
    this.title,
    this.iconUrl,
    this.subtitle,
    this.data,
  });
}

enum MapZoneType { polygon, polyline }

class MapZoneStyle {
  final String? fillColorHex;
  final double? fillOpacity;
  final String? strokeColorHex;
  final double? strokeWidth;
  final double? strokeOpacity;

  const MapZoneStyle({
    this.fillColorHex,
    this.fillOpacity,
    this.strokeColorHex,
    this.strokeWidth,
    this.strokeOpacity,
  });
}

class MapZoneModel {
  final String id;
  final MapZoneType type;
  final List<GeoPoint> points;
  final MapZoneStyle? style;
  final String? name;

  const MapZoneModel({
    required this.id,
    required this.type,
    required this.points,
    this.style,
    this.name,
  });
}
