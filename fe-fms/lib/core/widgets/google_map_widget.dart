import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fms/core/models/geo.dart';

/// Breathing room (logical px) kept between framed content and the edges of
/// the *visible* map area when fitting to [GoogleMapWidget.fitBounds].
const double _kFitPadding = 40;

/// A map widget implementation using `google_maps_flutter`.
class GoogleMapWidget extends StatefulWidget {
  final GeoPoint center;
  final double zoom;
  final List<MapMarkerModel> markers;
  final List<MapZoneModel> zones;
  final void Function(MapMarkerModel marker)? onMarkerTap;
  final int recenterTick;

  /// When non-null the camera frames this box instead of [center]/[zoom].
  final GeoBounds? fitBounds;

  /// Logical pixels obscured at the bottom of the map by the job panel.
  final double bottomInset;

  /// Logical pixels at the top of the map kept clear of framed content — the
  /// status bar / notch / Dynamic Island region.
  final double topInset;

  const GoogleMapWidget({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.zones = const [],
    this.onMarkerTap,
    this.recenterTick = 0,
    this.fitBounds,
    this.bottomInset = 0,
    this.topInset = 0,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _controller;

  /// Rider marker bitmaps, rasterised once. [_riderCone] is the blue dot with
  /// a direction cone (used when a heading is known); [_riderDot] is the plain
  /// dot (used until then). Null until their async raster completes.
  BitmapDescriptor? _riderCone;
  BitmapDescriptor? _riderDot;

  /// Numbered job-pin bitmaps, keyed by the stop label. Rasterised lazily and
  /// cached — there are only as many as there are distinct stop numbers.
  final Map<String, BitmapDescriptor> _jobIcons = {};

  @override
  void initState() {
    super.initState();
    _buildRiderBitmap(withCone: true).then((icon) {
      if (mounted) setState(() => _riderCone = icon);
    });
    _buildRiderBitmap(withCone: false).then((icon) {
      if (mounted) setState(() => _riderDot = icon);
    });
  }

  /// Ensures a numbered job-pin bitmap exists for every [labels] entry.
  /// A placeholder is inserted synchronously so the raster is kicked off only
  /// once per label; the real bitmap replaces it via [setState] when ready.
  void _ensureJobIcons(Iterable<String> labels) {
    for (final label in labels) {
      if (_jobIcons.containsKey(label)) continue;
      _jobIcons[label] = BitmapDescriptor.defaultMarker;
      _buildJobPin(label).then((icon) {
        if (mounted) setState(() => _jobIcons[label] = icon);
      });
    }
  }

  /// Rasterises an amber disc carrying the stop [label], mirroring the
  /// flutter_map job marker so both map backends look the same.
  Future<BitmapDescriptor> _buildJobPin(String label) async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);
    const radius = size * 0.40;
    canvas.drawCircle(
      center.translate(0, size * 0.03),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius - size * 0.075,
      Paint()..color = const Color(0xFFF59E0B),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 36,
      height: 36,
    );
  }

  /// Rasterises the rider's location marker — a blue dot, plus a translucent
  /// direction cone fanning "up" from it when [withCone] is set. The cone is
  /// painted pointing north; google_maps_flutter rotates the bitmap natively
  /// to the driver's heading via [Marker.rotation]. Mirrors the flutter_map
  /// `_RiderMarkerPainter` so both map backends look the same.
  Future<BitmapDescriptor> _buildRiderBitmap({required bool withCone}) async {
    const size = 144.0;
    const center = Offset(size / 2, size / 2);
    const blue = Color(0xFF1976D2);
    const deg2rad = 3.14159265359 / 180.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (withCone) {
      const radius = size / 2;
      const halfSpread = 32 * deg2rad; // 32° to each side of "up"
      const up = -90 * deg2rad; // straight up in canvas coords
      final cone = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          up - halfSpread,
          halfSpread * 2,
          false,
        )
        ..close();
      canvas.drawPath(
        cone,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x801976D2), Color(0x001976D2)],
          ).createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );
    }

    // Drop shadow, white ring, blue core — the plain location dot.
    canvas.drawCircle(
      center.translate(0, size * 0.012),
      size * 0.16,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
    canvas.drawCircle(center, size * 0.15, Paint()..color = Colors.white);
    canvas.drawCircle(center, size * 0.115, Paint()..color = blue);

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 54,
      height: 54,
    );
  }

  @override
  void didUpdateWidget(GoogleMapWidget old) {
    super.didUpdateWidget(old);
    final c = _controller;
    if (c == null) return;

    // Fit mode: frame the route. Re-fit when the box moves, when the obscuring
    // panel resizes (so the route re-centres into the new visible area), or on
    // an explicit recenter request.
    if (widget.fitBounds != null) {
      final boundsChanged = widget.fitBounds != old.fitBounds;
      final insetChanged = widget.bottomInset != old.bottomInset;
      final recenterRequested = widget.recenterTick != old.recenterTick;
      if (boundsChanged || insetChanged || recenterRequested) {
        _fitToBounds();
      }
      return;
    }

    final centerChanged = old.center.lat != widget.center.lat ||
        old.center.lng != widget.center.lng;
    final zoomChanged = old.zoom != widget.zoom;
    final recenterRequested = old.recenterTick != widget.recenterTick;
    if (centerChanged || zoomChanged || recenterRequested) {
      if (recenterRequested) {
        // An explicit recenter also re-orients the map to north-up
        // (bearing 0) and flat (tilt 0).
        c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(widget.center.lat, widget.center.lng),
              zoom: widget.zoom,
              bearing: 0,
              tilt: 0,
            ),
          ),
        );
      } else {
        c.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(widget.center.lat, widget.center.lng),
            widget.zoom,
          ),
        );
      }
    }
  }

  /// Frames [GoogleMapWidget.fitBounds]. The bottom-panel offset is handled by
  /// the `GoogleMap.padding` set in [build] — Google fits `newLatLngBounds`
  /// into the padded (visible) region — so here we only add a uniform margin.
  /// Deferred a frame so any padding change from this same rebuild is applied
  /// to the native view before the camera animates.
  void _fitToBounds() {
    final b = widget.fitBounds;
    if (b == null) return;
    final update = CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(b.southWest.lat, b.southWest.lng),
        northeast: LatLng(b.northEast.lat, b.northEast.lng),
      ),
      _kFitPadding,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller?.animateCamera(update);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kick off rasterising any numbered job-pin bitmaps not yet cached.
    _ensureJobIcons(widget.markers
        .where((m) => m.kind == MapMarkerKind.job && m.label != null)
        .map((m) => m.label!));

    final markers = widget.markers
        .map(
          (m) {
            // The rider marker is the blue location dot — with a direction
            // cone once a heading is known, a plain dot until then. Falls
            // back to a default pin only while the bitmaps rasterise.
            final isRider = m.kind == MapMarkerKind.rider;
            final riderIcon = !isRider
                ? null
                : m.rotation != null
                    ? (_riderCone ?? _riderDot)
                    : (_riderDot ?? _riderCone);
            // Job markers use the rasterised numbered amber disc once ready.
            final jobIcon = !isRider && m.label != null
                ? _jobIcons[m.label]
                : null;
            final useJobIcon =
                jobIcon != null && jobIcon != BitmapDescriptor.defaultMarker;
            return Marker(
            markerId: MarkerId(m.id),
            position: LatLng(m.position.lat, m.position.lng),
            rotation: m.rotation ?? 0.0,
            // Disc-shaped icons (rider dot, numbered job pin) pivot about
            // their centre; the fallback pin keeps the bottom-tip anchor.
            anchor: (riderIcon != null || useJobIcon)
                ? const Offset(0.5, 0.5)
                : const Offset(0.5, 1.0),
            icon: riderIcon ??
                (useJobIcon
                    ? jobIcon
                    : isRider
                        ? BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          )
                        : BitmapDescriptor.defaultMarker),
            infoWindow: InfoWindow(
              title: m.title,
              snippet: m.subtitle,
              onTap: widget.onMarkerTap != null
                  ? () => widget.onMarkerTap!(m)
                  : null,
            ),
            onTap: widget.onMarkerTap != null
                ? () => widget.onMarkerTap!(m)
                : null,
          );
          },
        )
        .toSet();

    final polygons = widget.zones
        .where((z) => z.type == MapZoneType.polygon)
        .map(
          (zone) => Polygon(
            polygonId: PolygonId(zone.id),
            points: zone.points.map((p) => LatLng(p.lat, p.lng)).toList(),
            fillColor:
                _parseColor(
                  zone.style?.fillColorHex,
                  zone.style?.fillOpacity,
                ) ??
                Colors.blue.withValues(alpha: 0.2),
            strokeColor:
                _parseColor(
                  zone.style?.strokeColorHex,
                  zone.style?.strokeOpacity,
                ) ??
                Colors.blue,
            strokeWidth: (zone.style?.strokeWidth ?? 2).round(),
          ),
        )
        .toSet();

    final polylines = widget.zones
        .where((z) => z.type == MapZoneType.polyline)
        .map(
          (zone) => Polyline(
            polylineId: PolylineId(zone.id),
            points: zone.points.map((p) => LatLng(p.lat, p.lng)).toList(),
            color:
                _parseColor(
                  zone.style?.strokeColorHex,
                  zone.style?.strokeOpacity,
                ) ??
                Colors.blue,
            width: (zone.style?.strokeWidth ?? 2).round(),
          ),
        )
        .toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Never let the panel claim the whole map — keep at least 20% of the
        // height usable so the camera always has somewhere to frame content.
        final maxInset = constraints.maxHeight.isFinite
            ? constraints.maxHeight * 0.8
            : widget.bottomInset;
        final inset = widget.bottomInset.clamp(0.0, maxInset);
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.center.lat, widget.center.lng),
            zoom: widget.zoom,
          ),
          // Insets the camera's usable region: camera operations centre/fit
          // content into the area between the status bar / notch and the job
          // panel, not the raw viewport.
          padding: EdgeInsets.only(top: widget.topInset, bottom: inset),
          markers: markers,
          polygons: polygons,
          polylines: polylines,
          onMapCreated: (c) {
            _controller = c;
            if (widget.fitBounds != null) _fitToBounds();
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );
      },
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
    final baseColor = Color(value);
    if (opacity != null) {
      return baseColor.withValues(alpha: opacity.clamp(0, 1));
    }
    return baseColor;
  }
}
