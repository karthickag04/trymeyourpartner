import '../../core/services/saved_search_service.dart';
import '../../shared/models/saved_search.dart';
import 'http_client.dart';

class HttpSavedSearchService implements SavedSearchService {
  final ApiClient _api;
  HttpSavedSearchService(this._api);

  @override
  Future<SavedSearch> create(
    String profileId,
    String name,
    Map<String, dynamic> filterJson, {
    bool alertEnabled = false,
  }) async {
    final res = await _api.post(
      '/saved-searches',
      body: {
        'profile_id': profileId,
        'name': name,
        'filter_json': filterJson,
        'alert_enabled': alertEnabled,
      },
    );
    if (res is Map) {
      return SavedSearch.fromMap(res.map((k, v) => MapEntry(k.toString(), v)));
    }
    // Fallback minimal mapping
    return SavedSearch(
      id: (res?['id'] ?? '').toString(),
      profileId: profileId,
      name: name,
      filter: filterJson,
      alertEnabled: alertEnabled,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<SavedSearch>> list(String profileId) async {
    final res = await _api.get(
      '/saved-searches',
      query: {'profile_id': profileId},
    );
    final list = (res is Map && res['items'] is List)
        ? res['items'] as List
        : (res is List ? res : const []);
    return list
        .whereType<Map>()
        .map(
          (m) =>
              SavedSearch.fromMap(m.map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();
  }

  @override
  Future<void> delete(String profileId, String id) async {
    await _api.delete('/saved-searches/$id', body: {'profile_id': profileId});
  }

  @override
  Future<SavedSearch> toggleAlert(
    String profileId,
    String id,
    bool enabled,
  ) async {
    final res = await _api.post(
      '/saved-searches/$id/toggle-alert',
      body: {'profile_id': profileId, 'alert_enabled': enabled},
    );
    if (res is Map) {
      return SavedSearch.fromMap(res.map((k, v) => MapEntry(k.toString(), v)));
    }
    return SavedSearch(
      id: id,
      profileId: profileId,
      name: '',
      filter: const {},
      alertEnabled: enabled,
      createdAt: DateTime.now(),
    );
  }
}
