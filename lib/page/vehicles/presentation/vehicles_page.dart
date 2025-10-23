import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fms/core/widgets/object_status_bottom_sheet.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';
import 'package:fms/data/models/traxroot_icon_model.dart';
import 'package:fms/data/models/traxroot_object_model.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';
import 'package:fms/page/vehicles/presentation/vehicle_tracking_page.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final _objectsDatasource = TraxrootObjectsDatasource(TraxrootAuthDatasource());

  bool _loading = false;
  List<TraxrootObjectModel> _objects = const [];
  Map<int, TraxrootIconModel> _iconsById = const {};
  int? _loadingObjectId;
  String _query = '';
  String? _selectedGroup;
  List<String> _availableGroups = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    try {
      final objects = await _objectsDatasource.getObjects();
      final icons = await _objectsDatasource.getObjectIcons();
      final iconMap = <int, TraxrootIconModel>{};
      for (final icon in icons) {
        final id = icon.id;
        if (id != null) {
          iconMap[id] = icon;
        }
      }
      if (!mounted) return;
      setState(() {
        _objects = objects;
        _iconsById = iconMap;
        _loading = false;
        final groups = objects
            .map((o) => o.service?.serverGroup)
            .where((g) => g != null && g.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();
        _availableGroups = groups;
        if (_selectedGroup != null && !_availableGroups.contains(_selectedGroup)) {
          _selectedGroup = null;
        }
      });
      if (iconMap.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          for (final icon in iconMap.values) {
            final url = icon.url;
            if (url != null && url.isNotEmpty) {
              precacheImage(NetworkImage(url), context);
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load vehicles. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final filtered = _objects.where((v) {
      final matchGroup = _selectedGroup == null || _selectedGroup!.isEmpty || v.service?.serverGroup == _selectedGroup;
      final name = (v.name ?? '').toLowerCase();
      final comment = (v.main?.comment ?? '').toLowerCase();
      final matchText = query.isEmpty || name.contains(query) || comment.contains(query);
      return matchGroup && matchText;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search vehicles',
                      hintText: 'Type name or note',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.group_outlined),
                      labelText: 'Group',
                    ),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem(value: '', child: Text('All groups')),
                      ..._availableGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    ],
                    onChanged: (value) => setState(() {
                      _selectedGroup = (value == null || value.isEmpty) ? null : value;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _loading && _objects.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final vehicle = filtered[index];
                      final iconId = vehicle.iconId;
                      final iconUrl = iconId != null ? _iconsById[iconId]?.url : null;
                      final subtitle = vehicle.main?.comment;
                      final isBusy = _loadingObjectId != null && vehicle.id == _loadingObjectId;

                      return Card(
                        child: ListTile(
                          leading: _VehicleIcon(url: iconUrl),
                          title: Text(
                            vehicle.name ?? 'Object ${vehicle.id ?? index + 1}',
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: subtitle != null && subtitle.isNotEmpty
                              ? Text(
                                  subtitle,
                                  style: theme.textTheme.bodyMedium,
                                )
                              : null,
                          trailing: isBusy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Track',
                                      onPressed: vehicle.id == null ? null : () => _openVehicleTracking(vehicle),
                                      icon: const Icon(Icons.near_me_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Detail',
                                      onPressed: vehicle.id == null ? null : () => _showVehicleSummary(vehicle),
                                      icon: const Icon(Icons.info_outline),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showVehicleSummary(TraxrootObjectModel vehicle) async {
    final status = await _fetchObjectStatus(vehicle);
    if (!mounted || status == null) {
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(status: status),
    );
  }

  Future<void> _openVehicleTracking(TraxrootObjectModel vehicle) async {
    final status = await _fetchObjectStatus(vehicle);
    if (!mounted || status == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleTrackingPage(
          vehicle: status,
          iconUrl: vehicle.iconId != null ? _iconsById[vehicle.iconId!]?.url : null,
        ),
      ),
    );
  }

  Future<TraxrootObjectStatusModel?> _fetchObjectStatus(
    TraxrootObjectModel vehicle,
  ) async {
    final objectId = vehicle.id;

    if (objectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID kendaraan tidak tersedia.')),
      );
      return null;
    }

    if (!mounted) {
      return null;
    }
    setState(() {
      _loadingObjectId = objectId;
    });

    TraxrootObjectStatusModel? status;
    try {
      status = await _objectsDatasource.getLatestPoint(objectId: objectId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat detail kendaraan.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (_loadingObjectId == objectId) {
            _loadingObjectId = null;
          }
        });
      }
    }

    if (status != null) {
      return status;
    }

    return TraxrootObjectStatusModel(
      id: vehicle.id,
      name: vehicle.name,
      latitude: vehicle.latitude,
      longitude: vehicle.longitude,
      address: vehicle.address,
    );
  }
}

class _VehicleIcon extends StatelessWidget {
  const _VehicleIcon({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    final radius = BorderRadius.circular(8);

    Widget fallbackIcon() => const Icon(Icons.directions_car, size: 18);

    return Container
      (
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: (url == null || url!.isEmpty)
            ? Center(child: fallbackIcon())
            : CachedNetworkImage(
                imageUrl: url!,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                placeholder: (_, __) => Center(child: fallbackIcon()),
                errorWidget: (_, __, ___) => Center(child: fallbackIcon()),
              ),
      ),
    );
  }
}
