import 'package:flutter/material.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';

class ObjectStatusBottomSheet extends StatelessWidget {
  final TraxrootObjectStatusModel status;
  final VoidCallback? onTrack;
  final VoidCallback? onNavigate;
  const ObjectStatusBottomSheet({
    super.key,
    required this.status,
    this.onTrack,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = <String>[
      if (status.status != null && status.status!.isNotEmpty) status.status!,
      if (status.speed != null) 'Speed: ${status.speed!.toStringAsFixed(1)} km/h',
      if (status.course != null) 'Heading: ${status.course!.toStringAsFixed(0)}°',
    ].join(' • ');

    final updatedLabel = status.updatedAt != null
        ? _formatDateTime(status.updatedAt!)
        : 'Unknown';

    final coordinatesLabel = status.geoPoint != null
        ? '${status.geoPoint!.lat.toStringAsFixed(5)}, ${status.geoPoint!.lng.toStringAsFixed(5)}'
        : 'Not available';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(Icons.directions_bus_filled),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.name ?? status.trackerId ?? 'Vehicle',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(subtitle, style: theme.textTheme.bodyMedium),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Last update: $updatedLabel', style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Tracker ID', value: status.trackerId ?? '-'),
            _DetailRow(label: 'Coordinates', value: coordinatesLabel),
            _DetailRow(label: 'Altitude', value: status.altitude != null ? '${status.altitude!.toStringAsFixed(1)} m' : '-'),
            _DetailRow(label: 'Satellites', value: status.satellites?.toString() ?? '-'),
            _DetailRow(label: 'Accuracy', value: status.accuracy != null ? '${status.accuracy!.toStringAsFixed(1)} m' : '-'),
            if (status.address != null && status.address!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Address',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(status.address!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            if (onTrack != null || onNavigate != null)
              Row(
                children: [
                  if (onTrack != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onTrack,
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Track Vehicle'),
                      ),
                    ),
                  if (onTrack != null && onNavigate != null) const SizedBox(width: 12),
                  if (onNavigate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.navigation_outlined),
                        label: const Text('Navigate'),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
