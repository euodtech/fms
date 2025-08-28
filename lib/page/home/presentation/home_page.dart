import 'package:flutter/material.dart';
import 'package:fms/core/models/geo.dart';
import 'package:fms/core/widgets/adaptive_map.dart';
import 'package:fms/data/mock_data.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final center = MockData.manila;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: AdaptiveMap(
              center: center,
              zoom: 12.5,
              markers: MockData.vehicles
                  .map((v) => MapMarkerModel(id: v.id, position: v.location, title: v.name))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Vehicles', value: MockData.vehicles.length.toString())),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Open Jobs', value: MockData.jobs.length.toString())),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
