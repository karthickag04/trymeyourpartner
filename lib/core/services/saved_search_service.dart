import '../../shared/models/saved_search.dart';

abstract class SavedSearchService {
  Future<SavedSearch> create(
    String profileId,
    String name,
    Map<String, dynamic> filterJson, {
    bool alertEnabled = false,
  });

  Future<List<SavedSearch>> list(String profileId);

  Future<void> delete(String profileId, String id);

  Future<SavedSearch> toggleAlert(String profileId, String id, bool enabled);
}
