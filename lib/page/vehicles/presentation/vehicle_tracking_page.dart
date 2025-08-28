import 'package:flutter/material.dart';
import 'package:fms/core/models/geo.dart';
import 'package:fms/core/widgets/adaptive_map.dart';
import 'package:fms/data/mock_data.dart';

class VehicleTrackingPage extends StatelessWidget {
  final String vehicleId;
  const VehicleTrackingPage({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final v = MockData.vehicles.firstWhere((e) => e.id == vehicleId);
    final marker = MapMarkerModel(id: v.id, position: v.location, title: v.name);

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: AdaptiveMap(center: v.location, zoom: 15, markers: [marker]),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                title: Text(v.name),
                subtitle: Text('${v.plate} • ${v.status}\n${v.address}'),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
