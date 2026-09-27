import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campusar/data/models/survey/survey_session.dart';
import 'package:campusar/data/repositories/providers.dart';
import 'package:campusar/data/repositories/survey_repository.dart';
import 'package:campusar/features/survey/services/dataset_validator.dart';
import 'package:campusar/features/survey/services/path_processing_service.dart';
import 'package:campusar/features/survey/services/survey_export_service.dart';
import 'package:campusar/features/survey/services/survey_import_service.dart';

const _datasetVersion = '0.1.0-survey';

final pathProcessingServiceProvider = Provider<PathProcessingService>((ref) {
  return const PathProcessingService();
});

final datasetValidatorProvider = Provider<DatasetValidator>((ref) {
  return const DatasetValidator();
});

final surveyExportServiceProvider = Provider<SurveyExportService>((ref) {
  return const SurveyExportService();
});

final surveyImportServiceProvider = Provider<SurveyImportService>((ref) {
  return const SurveyImportService();
});

/// The current (or most recently started) survey session, created lazily
/// the first time the surveyor collects something. `autoDispose` is
/// deliberately NOT used here — Survey Mode should keep its active
/// session alive across screen navigation within one field visit.
final activeSurveySessionProvider =
    StateNotifierProvider<ActiveSessionController, AsyncValue<SurveySession>>((ref) {
  return ActiveSessionController(ref);
});

class ActiveSessionController extends StateNotifier<AsyncValue<SurveySession>> {
  ActiveSessionController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repo = _ref.read(surveyRepositoryProvider);
    final existing = await repo.getActiveSession();
    if (existing != null) {
      state = AsyncValue.data(existing);
      return;
    }
    final session = await repo.startSession(datasetVersion: _datasetVersion);
    state = AsyncValue.data(session);
  }

  Future<void> endAndStartNew({String? notes}) async {
    final current = state.valueOrNull;
    if (current != null) {
      await _ref.read(surveyRepositoryProvider).endSession(current.id, notes: notes);
    }
    final session =
        await _ref.read(surveyRepositoryProvider).startSession(datasetVersion: _datasetVersion);
    state = AsyncValue.data(session);
  }
}

/// Live dashboard counts (section 3 of the V1.1 spec). Call
/// `ref.invalidate(surveyCountsProvider)` after any save so the Survey
/// Home screen updates immediately.
final surveyCountsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(surveyRepositoryProvider).getCounts();
});

final surveySnapshotProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(surveyRepositoryProvider).getSnapshot();
});

final surveyBuildingsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(surveyRepositoryProvider).listBuildings();
});

final surveyEntrancesForBuildingProvider =
    FutureProvider.autoDispose.family((ref, String buildingId) async {
  return ref.watch(surveyRepositoryProvider).listEntrancesForBuilding(buildingId);
});

final surveyFacilitiesProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(surveyRepositoryProvider).listFacilities();
});

final surveyNodesProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(surveyRepositoryProvider).listNodes();
});

final surveyEdgesProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(surveyRepositoryProvider).listEdges();
});

/// The official campus survey checklist (section 16 of the V1.1 spec) —
/// names/identifiers only, no coordinates, loaded from
/// assets/data/survey/survey_targets.json.
final surveyTargetsProvider = FutureProvider<List<SurveyTarget>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/survey/survey_targets.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final items = decoded['targets'] as List<dynamic>;
  return items
      .map((e) => SurveyTarget.fromJson(e as Map<String, dynamic>))
      .toList();
});

class SurveyTarget {
  const SurveyTarget({
    required this.number,
    required this.name,
    required this.category,
  });

  final int number;
  final String name;
  final String category;

  factory SurveyTarget.fromJson(Map<String, dynamic> json) => SurveyTarget(
        number: (json['number'] as num).toInt(),
        name: json['name'] as String,
        category: json['category'] as String,
      );
}
