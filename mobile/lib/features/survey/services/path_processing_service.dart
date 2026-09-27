import 'dart:math' as math;

import 'package:campusar/core/utilities/geo_utils.dart';
import 'package:campusar/data/models/survey/gps_sample.dart';

/// Result of processing one raw GPS track into a usable pathway (section 8
/// of the V1.1 spec).
class ProcessedPath {
  const ProcessedPath({
    required this.points,
    required this.rawCount,
    required this.discardedForAccuracy,
    required this.discardedAsDuplicate,
    required this.discardedBySimplification,
  });

  /// The final, simplified sequence of points to turn into route nodes,
  /// in walking order.
  final List<GpsSample> points;

  final int rawCount;
  final int discardedForAccuracy;
  final int discardedAsDuplicate;
  final int discardedBySimplification;

  int get keptCount => points.length;
}

/// Turns a raw walked GPS track into a clean, minimal set of route-node
/// points (section 8: "Do NOT simply save every raw GPS sample as a
/// routing node"). Three stages, each individually unit-testable:
///
/// 1. [filterByAccuracy] — drops points whose reported accuracy is worse
///    than a threshold (GPS noise / multipath near buildings).
/// 2. [removeNearDuplicates] — collapses points recorded while standing
///    still (or walking very slowly) into one.
/// 3. [simplify] — Douglas-Peucker line simplification, so a straight
///    stretch of path becomes 2 points instead of 200, while corners and
///    curves are preserved.
class PathProcessingService {
  const PathProcessingService();

  ProcessedPath process(
    List<GpsSample> rawSamples, {
    double maxAccuracyMeters = 20.0,
    double minPointSpacingMeters = 2.0,
    double simplificationToleranceMeters = 3.0,
  }) {
    final rawCount = rawSamples.length;

    final accurate = filterByAccuracy(rawSamples, maxAccuracyMeters);
    final discardedForAccuracy = rawCount - accurate.length;

    final deduped = removeNearDuplicates(accurate, minPointSpacingMeters);
    final discardedAsDuplicate = accurate.length - deduped.length;

    final simplified = simplify(deduped, simplificationToleranceMeters);
    final discardedBySimplification = deduped.length - simplified.length;

    return ProcessedPath(
      points: simplified,
      rawCount: rawCount,
      discardedForAccuracy: discardedForAccuracy,
      discardedAsDuplicate: discardedAsDuplicate,
      discardedBySimplification: discardedBySimplification,
    );
  }

  /// Drops samples whose reported accuracy is worse (a larger meter
  /// value) than [maxAccuracyMeters]. This is GPS noise removal, not the
  /// same threshold used for "is this good enough to save a building
  /// pin" (see GpsQualityThresholds) — a path can tolerate slightly
  /// noisier points than a single high-stakes building coordinate.
  List<GpsSample> filterByAccuracy(List<GpsSample> samples, double maxAccuracyMeters) {
    return samples.where((s) => s.accuracy <= maxAccuracyMeters).toList();
  }

  /// Collapses consecutive points closer together than
  /// [minDistanceMeters] (e.g. the surveyor paused, or GPS jitter while
  /// stationary) down to the first of the group.
  List<GpsSample> removeNearDuplicates(List<GpsSample> samples, double minDistanceMeters) {
    if (samples.isEmpty) return const [];
    final result = <GpsSample>[samples.first];
    for (final sample in samples.skip(1)) {
      final last = result.last;
      final d = GeoUtils.haversineDistanceMeters(
        last.latitude,
        last.longitude,
        sample.latitude,
        sample.longitude,
      );
      if (d >= minDistanceMeters) {
        result.add(sample);
      }
    }
    return result;
  }

  /// Ramer-Douglas-Peucker simplification. Distances are computed in a
  /// local flat-earth (equirectangular) projection centered on the
  /// track's first point — accurate enough for a single campus-scale
  /// track (a few hundred meters), much simpler than great-circle
  /// perpendicular-distance math, and this is exactly the kind of
  /// approximation that's fine at this scale but documented rather than
  /// silently assumed.
  List<GpsSample> simplify(List<GpsSample> samples, double toleranceMeters) {
    if (samples.length < 3) return samples;

    final origin = samples.first;
    final points = samples
        .map((s) => _LocalPoint(_projectX(origin, s), _projectY(origin, s), s))
        .toList();

    final keptIndices = <int>{0, points.length - 1};
    _rdp(points, 0, points.length - 1, toleranceMeters, keptIndices);

    final sortedIndices = keptIndices.toList()..sort();
    return sortedIndices.map((i) => points[i].sample).toList();
  }

  void _rdp(
    List<_LocalPoint> points,
    int startIndex,
    int endIndex,
    double tolerance,
    Set<int> keep,
  ) {
    if (endIndex <= startIndex + 1) return;

    final start = points[startIndex];
    final end = points[endIndex];
    double maxDist = -1;
    int maxIndex = -1;

    for (var i = startIndex + 1; i < endIndex; i++) {
      final d = _perpendicularDistance(points[i], start, end);
      if (d > maxDist) {
        maxDist = d;
        maxIndex = i;
      }
    }

    if (maxDist > tolerance && maxIndex != -1) {
      keep.add(maxIndex);
      _rdp(points, startIndex, maxIndex, tolerance, keep);
      _rdp(points, maxIndex, endIndex, tolerance, keep);
    }
  }

  double _perpendicularDistance(_LocalPoint p, _LocalPoint a, _LocalPoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2));
    }
    final numerator = ((dy * p.x) - (dx * p.y) + (b.x * a.y) - (b.y * a.x)).abs();
    final denominator = math.sqrt(lengthSquared);
    return numerator / denominator;
  }

  double _projectX(GpsSample origin, GpsSample p) {
    final metersPerDegreeLon =
        111320.0 * math.cos(origin.latitude * math.pi / 180.0);
    return (p.longitude - origin.longitude) * metersPerDegreeLon;
  }

  double _projectY(GpsSample origin, GpsSample p) {
    const metersPerDegreeLat = 111320.0;
    return (p.latitude - origin.latitude) * metersPerDegreeLat;
  }
}

class _LocalPoint {
  const _LocalPoint(this.x, this.y, this.sample);
  final double x;
  final double y;
  final GpsSample sample;
}
