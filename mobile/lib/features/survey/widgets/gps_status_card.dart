import 'package:flutter/material.dart';

import 'package:campusar/data/models/survey/gps_sample.dart';

/// Shows current GPS coordinates, accuracy, and a color-coded quality
/// label (section 4 of the V1.1 spec: "Allow the surveyor to see the
/// current accuracy before saving").
class GpsStatusCard extends StatelessWidget {
  const GpsStatusCard({
    super.key,
    required this.sample,
    this.thresholds = GpsQualityThresholds.defaults,
    this.compact = false,
  });

  final GpsSample? sample;
  final GpsQualityThresholds thresholds;
  final bool compact;

  Color _colorFor(GpsQualityLevel level, ColorScheme scheme) => switch (level) {
        GpsQualityLevel.excellent => Colors.green,
        GpsQualityLevel.good => Colors.lightGreen,
        GpsQualityLevel.warning => Colors.orange,
        GpsQualityLevel.poor => scheme.error,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = sample;

    if (s == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Waiting for GPS fix...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    final level = thresholds.classify(s.accuracy);
    final color = _colorFor(level, scheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '${level.label} · ±${s.accuracy.toStringAsFixed(1)}m',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                '${s.latitude.toStringAsFixed(6)}, ${s.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (s.altitude != null)
                Text('Altitude: ${s.altitude!.toStringAsFixed(1)} m',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
