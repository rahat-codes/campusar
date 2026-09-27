import 'dart:convert';
import 'dart:io';

import 'package:campusar/data/models/survey/survey_building.dart';
import 'package:campusar/data/models/survey/survey_entrance.dart';
import 'package:campusar/data/models/survey/survey_facility.dart';
import 'package:campusar/data/models/survey/survey_route_edge.dart';
import 'package:campusar/data/models/survey/survey_route_node.dart';
import 'package:campusar/data/models/survey/survey_session.dart';
import 'package:campusar/data/repositories/survey_repository.dart';

class SurveyImportException implements Exception {
  SurveyImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads a previously-exported `tongmyong-campus-dataset.json` (see
/// SurveyExportService.exportRaw) back into a [SurveySnapshot] the
/// repository can import (section 21 of the V1.1 spec).
///
/// This app intentionally does not add a file-picker dependency (section
/// 27: "Do not introduce unnecessary third-party dependencies") — the
/// import screen asks for an absolute file path instead, which the
/// surveyor gets from the export screen or from `adb push`ing a file
/// onto the device. See README "How to import data".
class SurveyImportService {
  const SurveyImportService();

  Future<SurveySnapshot> readFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw SurveyImportException('File not found: $path');
    }

    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on FormatException {
      throw SurveyImportException('That file is not valid JSON.');
    }

    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fromMap) {
      final raw = data[key] as List<dynamic>? ?? const [];
      return raw.map((e) => fromMap(e as Map<String, dynamic>)).toList();
    }

    try {
      return SurveySnapshot(
        sessions: parseList('surveySessions', SurveySession.fromMap),
        buildings: parseList('buildings', SurveyBuilding.fromMap),
        entrances: parseList('entrances', SurveyEntrance.fromMap),
        facilities: parseList('facilities', SurveyFacility.fromMap),
        nodes: parseList('routeNodes', SurveyRouteNode.fromMap),
        edges: parseList('routeEdges', SurveyRouteEdge.fromMap),
      );
    } catch (e) {
      throw SurveyImportException(
        "That file doesn't look like a CampusAR survey export (unexpected fields).",
      );
    }
  }
}
