import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/core/models/geo.dart';
import 'package:fms/data/datasource/get_job_datasource.dart';
import 'package:fms/data/datasource/get_job_ongoing_datasource.dart';
import 'package:fms/data/datasource/get_job_history_datasource.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/data/models/traxroot_icon_model.dart';
import 'package:fms/data/models/traxroot_object_model.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';
import 'package:fms/data/models/traxroot_geozone_model.dart';
import 'package:fms/data/models/response/get_job_history__response_model.dart'
    as history;
import 'dart:developer';
import 'package:fms/core/services/home_widget_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:fms/core/services/traxroot_credentials_manager.dart';
import 'package:fms/controllers/navigation_controller.dart';

class HomeController extends GetxController {
  final _objectsDatasource = TraxrootObjectsDatasource(
    TraxrootAuthDatasource(),
  );
  final _internalDatasource = TraxrootInternalDatasource();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<MapMarkerModel> markers = <MapMarkerModel>[].obs;
  final RxList<MapZoneModel> zones = <MapZoneModel>[].obs;
  final RxList<TraxrootObjectStatusModel> objects =
      <TraxrootObjectStatusModel>[].obs;
  final RxMap<int, String> iconUrlByObjectId = <int, String>{}.obs;
  final Rx<GetJobResponseModel?> allJobsResponse = Rx<GetJobResponseModel?>(
    null,
  );
  final Rx<GetJobResponseModel?> ongoingJobsResponse = Rx<GetJobResponseModel?>(
    null,
  );
  final Rx<history.GetJobHistoryResponseModel?> completedJobsResponse =
      Rx<history.GetJobHistoryResponseModel?>(null);

  static const GeoPoint defaultCenter = GeoPoint(
    14.5995,
    120.9842,
  ); // Manila fallback

  GeoPoint get mapCenter => defaultCenter;

  int get openJobsCount => allJobsResponse.value?.data?.length ?? 0;
  int get ongoingJobsCount => ongoingJobsResponse.value?.data?.length ?? 0;
  int get completedJobsCount => completedJobsResponse.value?.data?.length ?? 0;

  Future<TraxrootObjectStatusModel?> getObjectWithSensors(int objectId) {
    return _objectsDatasource.getObjectWithSensors(objectId: objectId);
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';

    try {
      final hasTraxrootCreds =
          await TraxrootCredentialsManager.hasCredentials();
      // Check for widget launch
      final widgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (widgetUri != null) {
        _handleWidgetNavigation(widgetUri);
      }

      // Listen for widget clicks while app is running
      HomeWidget.widgetClicked.listen(_handleWidgetNavigation);

      // Always load job-related data
      final allJobsFuture = GetJobDatasource().getJob();
      final ongoingJobsFuture = GetJobOngoingDatasource().getOngoingJobs();
      final completedJobsFuture = GetJobHistoryDatasource().getJobHistory();

      // Conditionally load Traxroot map/vehicle data only when credentials exist
      List<TraxrootObjectModel> objectsData = <TraxrootObjectModel>[];
      List<TraxrootIconModel> icons = <TraxrootIconModel>[];
      List<TraxrootGeozoneModel> geozones = <TraxrootGeozoneModel>[];

      if (hasTraxrootCreds) {
        final objectsFuture = _objectsDatasource.getObjects();
        final iconsFuture = _objectsDatasource.getObjectIcons();
        final geozonesFuture = _internalDatasource.getGeozones();

        objectsData = await objectsFuture;
        icons = await iconsFuture;
        geozones = await geozonesFuture;
      } else {
        error.value =
            'Unable to load map: Traxroot credentials are not configured. Please contact your administrator.';
      }

      final allJobs = await allJobsFuture;
      final ongoingJobs = await ongoingJobsFuture;
      final completedJobs = await completedJobsFuture;

      // Fetch all object IDs to get their status
      final objectIds = objectsData
          .where((obj) => obj.id != null)
          .map((obj) => obj.id!)
          .toList();

      // Fetch all statuses in parallel
      final statusFutures = objectIds.map(
        (id) => _objectsDatasource
            .getLatestPoint(objectId: id)
            .catchError((_) => null),
      );
      final allStatuses = await Future.wait(statusFutures);

      // Build status map by object ID
      final statusByObjectId = <int, TraxrootObjectStatusModel>{};
      for (var i = 0; i < objectIds.length; i++) {
        final status = allStatuses[i];
        if (status != null) {
          statusByObjectId[objectIds[i]] = status;
        }
      }

      final iconsById = <int, TraxrootIconModel>{
        for (final icon in icons)
          if (icon.id != null) icon.id!: icon,
      };

      final iconUrlMap = <int, String>{};
      final iconUrlByObjectName = <String, String>{};
      final iconUrlByTrackerId = <String, String>{};
      final trackersByObject = <int, Set<String>>{};

      for (final object in objectsData) {
        final objectId = object.id;
        if (objectId == null) continue;

        final iconId = object.iconId;
        if (iconId == null) continue;

        final iconUrl = iconsById[iconId]?.url;
        if (iconUrl != null && iconUrl.isNotEmpty) {
          iconUrlMap[objectId] = iconUrl;
          final name = object.name;
          if (name != null && name.isNotEmpty) {
            iconUrlByObjectName[name] = iconUrl;
          }

          void collectTrackers(dynamic node) {
            if (node is Map) {
              for (final entry in node.entries) {
                final key = '${entry.key}'.toLowerCase();
                final value = entry.value;
                if (key.contains('tracker') || key.contains('imei')) {
                  final text = value?.toString().trim();
                  if (text != null && text.isNotEmpty) {
                    iconUrlByTrackerId.putIfAbsent(text, () => iconUrl);
                    trackersByObject
                        .putIfAbsent(objectId, () => <String>{})
                        .add(text);
                  }
                }
                collectTrackers(value);
              }
            } else if (node is List) {
              for (final v in node) {
                collectTrackers(v);
              }
            }
          }

          collectTrackers(object.raw);
        }
      }

      // Build markers from /Objects (name, id, iconId) + extracted statuses (lat, lng)
      final markersList = <MapMarkerModel>[];
      final usedIconUrls = <String>{};
      final statusList = <TraxrootObjectStatusModel>[];

      for (final object in objectsData) {
        final objectId = object.id;
        if (objectId == null) continue;

        final objectName = object.name;
        final objectIconId = object.iconId;
        final iconUrl = objectIconId != null
            ? iconsById[objectIconId]?.url
            : null;

        if (iconUrl != null && iconUrl.isNotEmpty) {
          usedIconUrls.add(iconUrl);
        }

        // Get status from the map we built earlier
        final statusPoint = statusByObjectId[objectId];
        if (statusPoint == null) continue;

        final lat = statusPoint.latitude;
        final lon = statusPoint.longitude;
        if (lat == null || lon == null || (lat == 0.0 && lon == 0.0)) {
          continue;
        }

        // Compose status model with data from both endpoints
        final composed = TraxrootObjectStatusModel(
          id: objectId,
          name: objectName,
          trackerId: statusPoint.trackerId,
          latitude: lat,
          longitude: lon,
          address: statusPoint.address,
          speed: statusPoint.speed,
          course: statusPoint.course,
          altitude: statusPoint.altitude,
          status: statusPoint.status,
          updatedAt: statusPoint.updatedAt,
          satellites: statusPoint.satellites,
          accuracy: statusPoint.accuracy,
          iconId: objectIconId,
        );

        statusList.add(composed);
        final marker = composed.toMarker(icon: iconUrl);
        if (marker != null) {
          markersList.add(marker);
        }
      }

      final zonesList = <MapZoneModel>[];
      for (final geozone in geozones) {
        final zoneModel = geozone.toZoneModel();
        if (zoneModel != null) {
          zonesList.add(zoneModel);
        }
      }

      markers.value = markersList;
      zones.value = zonesList;
      objects.value = statusList;
      iconUrlByObjectId.value = iconUrlMap;
      allJobsResponse.value = allJobs;
      ongoingJobsResponse.value = ongoingJobs;
      completedJobsResponse.value = completedJobs;
      isLoading.value = false;

      _precacheIcons(usedIconUrls);
      _updateWidgets();
      if (error.value.isEmpty) {
        final authError = TraxrootAuthDatasource.lastErrorMessage;
        if (authError != null &&
            authError.toLowerCase().contains('invalid username or password')) {
          error.value =
              'Unable to load map: Traxroot credentials are invalid. Please contact your administrator.';
        }
      }
    } catch (e) {
      // On any Traxroot failure, keep job data but clear map-related state
      markers.clear();
      zones.clear();
      objects.clear();
      iconUrlByObjectId.clear();

      isLoading.value = false;

      final msg = e.toString();
      if (msg.toLowerCase().contains('invalid username or password')) {
        error.value =
            'Unable to load map: Traxroot credentials are invalid. Please contact your administrator.';
      } else {
        final authError = TraxrootAuthDatasource.lastErrorMessage;
        if (authError != null &&
            authError.toLowerCase().contains('invalid username or password')) {
          error.value =
              'Unable to load map: Traxroot credentials are invalid. Please contact your administrator.';
        } else {
          error.value = 'Failed to load map data. Please try again later.';
        }
      }
      // No Get.snackbar here to avoid Overlay-related errors; HomeTab already
      // displays error text under the map using controller.error.
    }
  }

  void _precacheIcons(Set<String> urls) {
    if (urls.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = Get.context;
        if (context != null) {
          for (final url in urls) {
            precacheImage(NetworkImage(url), context);
          }
        }
      });
    }
  }

  TraxrootObjectStatusModel? findStatusForMarker(MapMarkerModel marker) {
    final data = marker.data;
    if (data is TraxrootObjectStatusModel) {
      return data;
    }

    try {
      return objects.firstWhere(
        (obj) =>
            obj.geoPoint?.lat == marker.position.lat &&
            obj.geoPoint?.lng == marker.position.lng,
      );
    } catch (_) {
      return null;
    }
  }

  void _updateWidgets() {
    final widgetService = HomeWidgetService();

    // Prepare recent jobs (top 3 from all jobs)
    final recentJobs =
        allJobsResponse.value?.data
            ?.take(3)
            .map(
              (job) => {
                'title': job.jobName ?? 'Unknown Job',
                'status': job.typeJobName ?? 'Open',
                'time': job.jobDate?.toIso8601String() ?? '',
              },
            )
            .toList() ??
        [];

    // Update Job Stats
    widgetService.updateJobStats(
      open: openJobsCount,
      ongoing: ongoingJobsCount,
      complete: completedJobsCount,
      recentJobs: recentJobs,
    );

    // Update Map Stats
    widgetService.updateMapStats(
      activeVehicles: markers.length,
      markers: markers,
    );
  }

  void _handleWidgetNavigation(Uri? uri) {
    if (uri == null) return;

    try {
      final navController = Get.find<NavigationController>();

      if (uri.host == 'job') {
        // Navigate to Jobs tab (Index 2)
        navController.changeTab(2);
      } else if (uri.host == 'map') {
        // Navigate to Home/Map tab (Index 0)
        navController.changeTab(0);
      }
    } catch (e) {
      log('NavigationController not found: $e');
    }
  }

  void reset() {
    isLoading.value = false;
    error.value = '';
    markers.clear();
    zones.clear();
    objects.clear();
    iconUrlByObjectId.clear();
    allJobsResponse.value = null;
    ongoingJobsResponse.value = null;
    completedJobsResponse.value = null;
  }
}
