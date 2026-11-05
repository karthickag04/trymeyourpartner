import '../../core/services/icebreaker_service.dart';
import '../../models/icebreaker.dart';
import 'http_client.dart';

class HttpIcebreakerService implements IcebreakerService {
  final ApiClient _api;
  HttpIcebreakerService(this._api);

  @override
  Future<List<Icebreaker>> list({bool activeOnly = true}) async {
    final res = await _api.get(
      '/icebreakers',
      query: {if (activeOnly) 'active': true},
    );
    final items = (res is Map && res['items'] is List)
        ? res['items'] as List
        : (res is List ? res : const []);
    return items
        .whereType<Map>()
        .map(
          (m) => Icebreaker.fromMap(m.map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();
  }
}
