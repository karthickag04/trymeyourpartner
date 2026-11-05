import 'package:supabase_flutter/supabase_flutter.dart';
import 'subscription.dart';

class SubscriptionService {
  // Lazily access the Supabase client to avoid early initialization issues
  static SupabaseClient get _supabase => Supabase.instance.client;

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

  /// Reveals another member's phone numbers.
  ///
  /// The server checks the plan quota, blocks and profile status, records the
  /// reveal and returns the numbers (see `reveal_contact` in
  /// supabase/migrations). Repeat reveals of the same member use no quota.
  /// Throws [ContactLimitReached] when the plan's quota is used up.
  static Future<RevealedContact> revealContact(String targetProfileId) async {
    try {
      final res = await _supabase.rpc(
        'reveal_contact',
        params: {'p_target_profile_id': targetProfileId},
      );
      final map = Map<String, dynamic>.from(res as Map);
      return RevealedContact(
        phoneNumber: map['phone_number'] as String?,
        whatsappNumber: map['whatsapp_number'] as String?,
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('CONTACT_LIMIT_REACHED')) {
        throw const ContactLimitReached();
      }
      if (e.message.contains('PROFILE_NOT_AVAILABLE')) {
        throw const ContactUnavailable();
      }
      rethrow;
    }
  }
}

class RevealedContact {
  final String? phoneNumber;
  final String? whatsappNumber;
  const RevealedContact({this.phoneNumber, this.whatsappNumber});

  bool get isEmpty =>
      (phoneNumber ?? '').isEmpty && (whatsappNumber ?? '').isEmpty;
}

class ContactLimitReached implements Exception {
  const ContactLimitReached();
  @override
  String toString() => 'Contact reveal limit reached for your plan.';
}

class ContactUnavailable implements Exception {
  const ContactUnavailable();
  @override
  String toString() => 'This profile is not available.';
}
