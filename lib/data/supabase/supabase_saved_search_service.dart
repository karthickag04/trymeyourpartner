import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/saved_search_service.dart';
import '../../models/saved_search.dart';

class SupabaseSavedSearchService implements SavedSearchService {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<SavedSearch> create(
    String profileId,
    String name,
    Map<String, dynamic> filterJson, {
    bool alertEnabled = false,
  }) async {
    final res = await _db
        .from('saved_searches')
        .insert({
          'profile_id': profileId,
          'name': name,
          'filter_json': filterJson,
          'alert_enabled': alertEnabled,
        })
        .select()
        .single();
    return SavedSearch.fromMap(res);
  }

  @override
  Future<List<SavedSearch>> list(String profileId) async {
    final rows = await _db
        .from('saved_searches')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    return rows.map<SavedSearch>((m) => SavedSearch.fromMap(m)).toList();
  }

  @override
  Future<void> delete(String profileId, String id) async {
    await _db.from('saved_searches').delete().match({
      'id': id,
      'profile_id': profileId,
    });
  }

  @override
  Future<SavedSearch> toggleAlert(
    String profileId,
    String id,
    bool enabled,
  ) async {
    final res = await _db
        .from('saved_searches')
        .update({'alert_enabled': enabled})
        .match({'id': id, 'profile_id': profileId})
        .select()
        .single();
    return SavedSearch.fromMap(res);
  }
}
