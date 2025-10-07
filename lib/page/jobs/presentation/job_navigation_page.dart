import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../core/models/geo.dart';
import '../../../core/widgets/adaptive_map.dart';
import '../../../core/widgets/object_status_bottom_sheet.dart';
import '../../../data/datasource/traxroot_datasource.dart';
import '../../../data/models/traxroot_geozone_model.dart';
import '../../../data/models/traxroot_object_status_model.dart';
import '../../vehicles/presentation/vehicle_tracking_page.dart';

class JobNavigationPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String jobName;
  final String? address;
  const JobNavigationPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.jobName,
    this.address,
  });

  @override
  State<JobNavigationPage> createState() => _JobNavigationPageState();
}

class _JobNavigationPageState extends State<JobNavigationPage> {
  final _objectsDatasource = TraxrootObjectsDatasource(
    TraxrootAuthDatasource(),
  );
  final _internalDatasource = TraxrootInternalDatasource();

  bool _loading = false;
  List<MapMarkerModel> _markers = const [];
  List<MapZoneModel> _zones = const [];
  String? _error;

  GeoPoint get _jobPoint => GeoPoint(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final jobMarker = MapMarkerModel(
      id: 'job-destination',
      position: _jobPoint,
      title: widget.jobName,
      subtitle: widget.address,
    );

    setState(() {
      _markers = [jobMarker];
      _zones = const [];
    });

    final objectsStatusFuture = _objectsDatasource.getAllObjectsStatus();
    final geozonesFuture = _internalDatasource.getGeozones();

    final warnings = <String>[];

    List<TraxrootObjectStatusModel> objectsStatus = const [];
    List<TraxrootGeozoneModel> geozones = const [];

    try {
      try {
        objectsStatus = await objectsStatusFuture.timeout(
          const Duration(seconds: 12),
        );
      } on TimeoutException catch (_) {
        warnings.add('Fetching vehicle data takes longer than usual.');
      } catch (e, st) {
        warnings.add('Failed to load vehicle data.');
        log(
          'Failed to load Traxroot object status list',
          name: 'JobNavigationPage',
          error: e,
          stackTrace: st,
        );
      }

      try {
        geozones = await geozonesFuture.timeout(const Duration(seconds: 12));
      } on TimeoutException catch (_) {
        warnings.add('Fetching geozone data takes longer than usual.');
      } catch (e, st) {
        warnings.add('Failed to load geozone data.');
        log(
          'Failed to load Traxroot geozones',
          name: 'JobNavigationPage',
          error: e,
          stackTrace: st,
        );
      }

      if (!mounted) return;

      final markers = <MapMarkerModel>[jobMarker];
      for (final object in objectsStatus) {
        final marker = object.toMarker();
        if (marker != null) {
          markers.add(marker);
        }
      }

      final zones = <MapZoneModel>[];
      for (final geozone in geozones) {
        final zone = geozone.toZoneModel();
        if (zone != null) {
          zones.add(zone);
        }
      }

      setState(() {
        _markers = markers;
        _zones = zones;
        _loading = false;
        _error = warnings.isEmpty ? null : warnings.join('\n');
      });

      if (warnings.isNotEmpty && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(warnings.join('\n'))));
      }
    } catch (e, st) {
      if (!mounted) return;
      log(
        'Unexpected error while loading navigation data',
        name: 'JobNavigationPage',
        error: e,
        stackTrace: st,
      );
      setState(() {
        _loading = false;
        _error = 'Failed to load map data';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load map data')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Navigation'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.jobName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.address != null) ...[
                const SizedBox(height: 8),
                Text(widget.address!, style: theme.textTheme.bodyMedium),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  children: [
                    AdaptiveMap(
                      center: _jobPoint,
                      markers: _markers,
                      zones: _zones,
                      onMarkerTap: _handleMarkerTap,
                    ),
                    if (_loading)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0x33000000),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Markers: ${_markers.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Geozones: ${_zones.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMarkerTap(MapMarkerModel marker) {
    final status = marker.data;
    if (status is! TraxrootObjectStatusModel) {
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(
        status: status,
        onTrack: status.id != null
            ? () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleTrackingPage(vehicle: status),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
