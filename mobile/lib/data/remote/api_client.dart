import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:campusar/core/constants/api_constants.dart';
import 'package:campusar/core/errors/app_failure.dart';
import 'package:campusar/core/utilities/result.dart';

/// Thin wrapper around the FastAPI backend's REST API.
///
/// Used ONLY for optional background sync (section 17 "Offline-first
/// design" — Local Data -> Version Check -> Remote API -> Updated Campus
/// Data -> Local Database). Every method returns a [Result] and never
/// throws, so a missing/unreachable backend degrades gracefully to "stay
/// on local data" rather than crashing or blocking the UI.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) =>
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.apiV1Prefix}$path');

  Future<Result<String>> fetchCampusVersion() async {
    final result = await _getJsonObject('/campus/version');
    return result.when(
      success: (json) => Result.success(json['version'] as String),
      failure: (f) => Result.failure(f),
    );
  }

  Future<Result<Map<String, dynamic>>> fetchCampus() =>
      _getJsonObject('/campus');

  Future<Result<List<dynamic>>> fetchBuildings() => _getJsonList('/buildings');

  Future<Result<Map<String, dynamic>>> fetchRouteGraph() =>
      _getJsonObject('/routes');

  /// GETs [path] and decodes the body as a JSON object (a `{...}`).
  Future<Result<Map<String, dynamic>>> _getJsonObject(String path) async {
    try {
      final response =
          await _client.get(_uri(path)).timeout(ApiConstants.requestTimeout);
      if (response.statusCode != 200) {
        return Result.failure(NoInternetFailure());
      }
      final decoded = jsonDecode(response.body);
      return Result.success(decoded as Map<String, dynamic>);
    } catch (_) {
      return Result.failure(NoInternetFailure());
    }
  }

  /// GETs [path] and decodes the body as a JSON array (a `[...]`).
  Future<Result<List<dynamic>>> _getJsonList(String path) async {
    try {
      final response =
          await _client.get(_uri(path)).timeout(ApiConstants.requestTimeout);
      if (response.statusCode != 200) {
        return Result.failure(NoInternetFailure());
      }
      final decoded = jsonDecode(response.body);
      return Result.success(decoded as List<dynamic>);
    } catch (_) {
      return Result.failure(NoInternetFailure());
    }
  }

  void dispose() => _client.close();
}
