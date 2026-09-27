import 'package:campusar/data/models/survey/gps_sample.dart';
import 'package:campusar/data/repositories/survey_repository.dart';

enum ValidationLevel { pass, warning, error }

class ValidationResult {
  const ValidationResult(this.level, this.message);
  final ValidationLevel level;
  final String message;
}

/// Runs the checks listed in section 18 of the V1.1 spec against a
/// [SurveySnapshot]. Pure Dart, no database access itself, so it's easy
/// to unit test against hand-built snapshots.
class DatasetValidator {
  const DatasetValidator({this.thresholds = GpsQualityThresholds.defaults});

  final GpsQualityThresholds thresholds;

  List<ValidationResult> validate(SurveySnapshot snapshot) {
    final results = <ValidationResult>[];

    _checkDuplicateIds(snapshot, results);
    _checkCoordinates(snapshot, results);
    _checkGpsAccuracy(snapshot, results);
    _checkBuildingsHaveEntrances(snapshot, results);
    _checkDuplicateFacilities(snapshot, results);
    _checkOrphanEdges(snapshot, results);
    _checkZeroDistanceEdges(snapshot, results);
    _checkGraphConnectivity(snapshot, results);

    if (results.where((r) => r.level == ValidationLevel.error).isEmpty) {
      results.insert(
        0,
        ValidationResult(
          ValidationLevel.pass,
          '${snapshot.buildings.length} buildings, '
          '${snapshot.entrances.length} entrances, '
          '${snapshot.facilities.length} facilities, '
          '${snapshot.nodes.length} nodes, '
          '${snapshot.edges.length} edges checked.',
        ),
      );
    }

    return results;
  }

  void _checkDuplicateIds(SurveySnapshot s, List<ValidationResult> out) {
    void checkIds(String label, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) {
          out.add(ValidationResult(ValidationLevel.error, 'Duplicate $label ID: $id'));
        }
      }
    }

    checkIds('building', s.buildings.map((b) => b.id));
    checkIds('entrance', s.entrances.map((e) => e.id));
    checkIds('facility', s.facilities.map((f) => f.id));
    checkIds('route node', s.nodes.map((n) => n.id));
    checkIds('route edge', s.edges.map((e) => e.id));
  }

  bool _isValidCoordinate(double lat, double lon) {
    if (lat == 0 && lon == 0) return false; // classic "never captured" sentinel
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  void _checkCoordinates(SurveySnapshot s, List<ValidationResult> out) {
    for (final b in s.buildings) {
      if (!_isValidCoordinate(b.latitude, b.longitude)) {
        out.add(ValidationResult(
          ValidationLevel.error,
          'Building "${b.nameEn}" (${b.id}) has missing/invalid coordinates.',
        ));
      }
    }
    for (final e in s.entrances) {
      if (!_isValidCoordinate(e.latitude, e.longitude)) {
        out.add(ValidationResult(
          ValidationLevel.error,
          'Entrance ${e.id} has missing/invalid coordinates.',
        ));
      }
    }
    for (final f in s.facilities) {
      if (!_isValidCoordinate(f.latitude, f.longitude)) {
        out.add(ValidationResult(
          ValidationLevel.error,
          'Facility ${f.id} has missing/invalid coordinates.',
        ));
      }
    }
    for (final n in s.nodes) {
      if (!_isValidCoordinate(n.latitude, n.longitude)) {
        out.add(ValidationResult(
          ValidationLevel.error,
          'Route node ${n.id} has missing/invalid coordinates.',
        ));
      }
    }
  }

  void _checkGpsAccuracy(SurveySnapshot s, List<ValidationResult> out) {
    for (final b in s.buildings) {
      final acc = b.gpsAccuracy;
      if (acc != null && thresholds.classify(acc) == GpsQualityLevel.poor) {
        out.add(ValidationResult(
          ValidationLevel.warning,
          'Building "${b.nameEn}" was captured with poor GPS accuracy (±${acc.round()}m).',
        ));
      }
    }
    for (final n in s.nodes) {
      final acc = n.gpsAccuracy;
      if (acc != null && thresholds.classify(acc) == GpsQualityLevel.poor) {
        out.add(ValidationResult(
          ValidationLevel.warning,
          'Route node ${n.id} was captured with poor GPS accuracy (±${acc.round()}m).',
        ));
      }
    }
  }

  void _checkBuildingsHaveEntrances(SurveySnapshot s, List<ValidationResult> out) {
    final entranceBuildingIds = s.entrances.map((e) => e.buildingId).toSet();
    final verifiedEntranceBuildingIds = s.entrances
        .where((e) => e.status.name == 'verified')
        .map((e) => e.buildingId)
        .toSet();
    for (final b in s.buildings) {
      if (!entranceBuildingIds.contains(b.id)) {
        out.add(ValidationResult(
          ValidationLevel.warning,
          'Building "${b.nameEn}" has no recorded entrance.',
        ));
      } else if (!verifiedEntranceBuildingIds.contains(b.id)) {
        out.add(ValidationResult(
          ValidationLevel.warning,
          'Building "${b.nameEn}" has no verified entrance.',
        ));
      }
    }
  }

  void _checkDuplicateFacilities(SurveySnapshot s, List<ValidationResult> out) {
    final seen = <String, int>{};
    for (final f in s.facilities) {
      final key = '${f.buildingId ?? "-"}|${f.type}|${(f.name ?? "").toLowerCase()}';
      seen[key] = (seen[key] ?? 0) + 1;
    }
    seen.forEach((key, count) {
      if (count > 1) {
        out.add(ValidationResult(
          ValidationLevel.warning,
          'Possible duplicate facility entries for "$key" ($count records).',
        ));
      }
    });
  }

  void _checkOrphanEdges(SurveySnapshot s, List<ValidationResult> out) {
    final nodeIds = s.nodes.map((n) => n.id).toSet();
    for (final e in s.edges) {
      if (!nodeIds.contains(e.fromNode)) {
        out.add(ValidationResult(
          ValidationLevel.error,
          'Route edge ${e.id} references missing node ${e.fromNode}.',
        ));
      }
      if (!nodeIds.contains(e.toNode)) {
        out.add(ValidationResult(
          ValidationLevel.error,
          'Route edge ${e.id} references missing node ${e.toNode}.',
        ));
      }
    }
    final referencedNodeIds = {
      for (final e in s.edges) ...[e.fromNode, e.toNode],
    };
    for (final n in s.nodes) {
      if (!referencedNodeIds.contains(n.id)) {
        out.add(ValidationResult(
          ValidationLevel.warning,
          'Route node ${n.id} is not connected to any edge (orphan node).',
        ));
      }
    }
  }

  void _checkZeroDistanceEdges(SurveySnapshot s, List<ValidationResult> out) {
    for (final e in s.edges) {
      if (e.distance <= 0) {
        out.add(ValidationResult(
          ValidationLevel.error,
          'Route edge ${e.id} has zero (or negative) distance.',
        ));
      }
    }
  }

  void _checkGraphConnectivity(SurveySnapshot s, List<ValidationResult> out) {
    if (s.nodes.isEmpty) return;
    final adjacency = <String, List<String>>{};
    for (final n in s.nodes) {
      adjacency[n.id] = [];
    }
    for (final e in s.edges) {
      adjacency.putIfAbsent(e.fromNode, () => []).add(e.toNode);
      adjacency.putIfAbsent(e.toNode, () => []).add(e.fromNode);
    }

    final visited = <String>{};
    var componentCount = 0;
    for (final start in adjacency.keys) {
      if (visited.contains(start)) continue;
      componentCount++;
      final queue = [start];
      visited.add(start);
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        for (final neighbor in adjacency[current] ?? const []) {
          if (visited.add(neighbor)) {
            queue.add(neighbor);
          }
        }
      }
    }

    if (componentCount > 1) {
      out.add(ValidationResult(
        ValidationLevel.warning,
        'The route graph has $componentCount disconnected sections — some '
        'paths cannot reach each other yet.',
      ));
    }
  }
}
