import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/icebreaker_service.dart';
import '../../models/icebreaker.dart';

class SupabaseIcebreakerService implements IcebreakerService {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<Icebreaker>> list({bool activeOnly = true}) async {
    var query = _db.from('icebreakers').select();
    if (activeOnly) {
      query = query.eq('active', true);
    }
    final rows = await query.order('weight', ascending: false);
    return rows
        .whereType<Map>()
        .map((m) => Icebreaker.fromMap(m.cast<String, dynamic>()))
        .toList();
  }
}
