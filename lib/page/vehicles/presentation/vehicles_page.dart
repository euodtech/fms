import 'package:flutter/material.dart';
import 'package:fms/data/mock_data.dart';
import 'package:fms/page/vehicles/presentation/vehicle_tracking_page.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: MockData.vehicles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = MockData.vehicles[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      v.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: v.status == 'Active'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        v.status,
                        style: TextStyle(
                          color: v.status == 'Active'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Plate: ${v.plate}'),
                const SizedBox(height: 6),
                Text(v.address, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                VehicleTrackingPage(vehicleId: v.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.near_me_outlined),
                      label: const Text('TRACK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
