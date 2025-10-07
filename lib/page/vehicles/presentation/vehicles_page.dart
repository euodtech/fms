import 'package:flutter/material.dart';
import 'package:fms/core/widgets/object_status_bottom_sheet.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';
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
  List<TraxrootObjectStatusModel> _objects = const [];

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
      final objects = await _objectsDatasource.getAllObjectsStatus();
      if (!mounted) return;
      setState(() {
        _objects = objects;
        _loading = false;
      });
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _loading && _objects.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _objects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vehicle = _objects[index];
                final hasLocation = vehicle.geoPoint != null;
                final status = vehicle.status ?? 'Unknown';
                final updatedAt = vehicle.updatedAt?.toLocal();
                final updatedLabel = updatedAt != null
                    ? '${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')} ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}'
                    : null;

                final isActive = (status.toLowerCase().contains('active') || status.toLowerCase().contains('online'));

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                vehicle.name ?? 'Object ${vehicle.id ?? index + 1}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: (isActive ? Colors.green : Colors.orange).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (vehicle.address != null && vehicle.address!.isNotEmpty)
                          Text(vehicle.address!, style: Theme.of(context).textTheme.bodyMedium),
                        if (vehicle.speed != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('Speed: ${vehicle.speed!.toStringAsFixed(1)} km/h'),
                          ),
                        if (updatedLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('Updated: $updatedLabel', style: Theme.of(context).textTheme.bodySmall),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: !hasLocation || vehicle.id == null
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => VehicleTrackingPage(
                                            vehicle: vehicle,
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.near_me_outlined),
                              label: const Text('TRACK'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showVehicleSummary(vehicle),
                              icon: const Icon(Icons.info_outline),
                              label: const Text('DETAIL'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showVehicleSummary(TraxrootObjectStatusModel vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(status: vehicle),
    );
  }
}
