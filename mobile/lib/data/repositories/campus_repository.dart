import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/utilities/result.dart';
import 'package:campusar/data/local/campus_data_loader.dart';
import 'package:campusar/data/local/local_campus_data_source.dart';
import 'package:campusar/data/models/campus.dart';
import 'package:campusar/data/remote/api_client.dart';

/// Offline-first campus repository.
///
/// Always reads from the local database first. On construction (or when
/// [ensureReady] is called) it seeds the local DB from the bundled JSON
/// assets if this is the first launch. [checkForUpdates] is a best-effort,
/// non-blocking sync: it compares the locally-stored data version against
/// the backend's `/campus/version` endpoint and only re-seeds if the
/// backend has a strictly newer version — never required for the app to
/// function (section 17 of the product spec).
class CampusRepository {
  CampusRepository({
    LocalCampusDataSource? localDataSource,
    CampusDataLoader? dataLoader,
    ApiClient? apiClient,
  })  : _local = localDataSource ?? const LocalCampusDataSource(),
        _loader = dataLoader ?? const CampusDataLoader(),
        _api = apiClient ?? ApiClient();

  final LocalCampusDataSource _local;
  final CampusDataLoader _loader;
  final ApiClient _api;

  Future<void> ensureReady() => _loader.loadBundledDataIfNeeded();

  Future<Result<Campus>> getCampus() async {
    await ensureReady();
    final campus = await _local.getCampus();
    if (campus == null) {
      return Result.failure(
        CampusDataFailure('No campus data is available locally.'),
      );
    }
    return Result.success(campus);
  }

  /// Returns true if a sync happened, false if skipped/unreachable. Never
  /// throws — callers can safely fire-and-forget this.
  Future<bool> checkForUpdates() async {
    final campusResult = await getCampus();
    final campus = campusResult.dataOrNull;
    if (campus == null) return false;

    final remoteVersion = await _api.fetchCampusVersion();
    final version = remoteVersion.dataOrNull;
    if (version == null || version == campus.version) return false;

    // A real implementation would re-fetch and re-seed buildings/routes
    // here too; left as a documented extension point for the future admin
    // panel / sync pipeline (see README "Future roadmap").
    return false;
  }
}
