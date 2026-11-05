import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';

class SubscriptionService {
  // Lazily access the Supabase client to avoid early initialization issues
  static SupabaseClient get _supabase => Supabase.instance.client;

  static Future<Subscription> ensureDefaultFree(String profileId) async {
    // Look up active subscription
    final now = DateTime.now().toIso8601String();
    final existing = await _supabase
        .from('subscriptions')
        .select()
        .eq('profile_id', profileId)
        .lte('start_at', now)
        .or('end_at.is.null,end_at.gt.$now')
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return Subscription.fromJson(existing);
    }

    // Create a free subscription starting now with endAt = end of current month
    final startAt = DateTime.now();
    final endAt = DateTime(
      startAt.year,
      startAt.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
    final insert = await _supabase
        .from('subscriptions')
        .insert({
          'profile_id': profileId,
          'tier': 'free',
          'start_at': startAt.toIso8601String(),
          'end_at': endAt.toIso8601String(),
        })
        .select()
        .single();
    return Subscription.fromJson(insert);
  }

  static Future<Subscription?> getActive(String profileId) async {
    final now = DateTime.now().toIso8601String();
    final row = await _supabase
        .from('subscriptions')
        .select()
        .eq('profile_id', profileId)
        .lte('start_at', now)
        .or('end_at.is.null,end_at.gt.$now')
        .order('start_at')
        .limit(1)
        .maybeSingle();
    return row == null ? null : Subscription.fromJson(row);
  }

  static Future<int> getMonthlyContactReveals(String profileId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final nextMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

    final resp = await _supabase
        .from('contact_reveals')
        .select('id')
        .eq('profile_id', profileId)
        .gte('created_at', monthStart)
        .lt('created_at', nextMonth);
    return (resp as List).length;
  }

  static Future<bool> canRevealContact(String viewerProfileId) async {
    final sub = await getActive(viewerProfileId);
    if (sub == null)
      return false; // should not happen; call ensureDefaultFree first

    final int? limit = PlanRules.contactLimitFor(
      sub.tier,
      sub.startAt,
      sub.endAt,
    );
    if (limit == null) return true; // unlimited
    if (sub.tier == PlanTier.free) {
      final used = await getMonthlyContactReveals(viewerProfileId);
      return used < PlanRules.freeMonthlyContactLimit;
    }
    // Paid with finite limit
    final List resp = await _supabase
        .from('contact_reveals')
        .select('id')
        .eq('profile_id', viewerProfileId)
        .gte('created_at', sub.startAt.toIso8601String())
        .lt('created_at', (sub.endAt ?? DateTime.now()).toIso8601String());
    final used = resp.length;
    return used < limit; // limit is non-null here
  }

  static Future<void> recordContactReveal(
    String viewerProfileId,
    String viewedProfileId,
  ) async {
    // Use upsert to avoid duplicate key error if already recorded (e.g., via accept RPC)
    await _supabase.from('contact_reveals').upsert({
      'profile_id': viewerProfileId,
      'viewed_profile_id': viewedProfileId,
    }, onConflict: 'profile_id,viewed_profile_id');
  }
}
