import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/contact_exchange_service.dart';
import '../../shared/models/contact_request.dart';

class SupabaseContactExchangeService implements ContactExchangeService {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<String> request(
    String requesterProfileId,
    String targetProfileId,
  ) async {
    final res = await _db
        .from('contact_requests')
        .insert({
          'requester_profile_id': requesterProfileId,
          'target_profile_id': targetProfileId,
          'status': 'pending',
        })
        .select('id')
        .single();
    return (res['id'] ?? '').toString();
  }

  @override
  Future<void> accept(String myProfileId, String requesterProfileId) async {
    await _db.rpc(
      'accept_contact_request',
      params: {'p_requester_profile_id': requesterProfileId},
    );
  }

  @override
  Future<void> decline(String myProfileId, String requesterProfileId) async {
    await _db.from('contact_requests').update({'status': 'declined'}).match({
      'requester_profile_id': requesterProfileId,
      'target_profile_id': myProfileId,
      'status': 'pending',
    });
  }

  @override
  Future<ContactHandshakeStatus> getStatus(
    String myProfileId,
    String otherProfileId,
  ) async {
    final rows = await _db
        .from('contact_requests')
        .select('requester_profile_id,target_profile_id,status')
        .or(
          'and(requester_profile_id.eq.$myProfileId,target_profile_id.eq.$otherProfileId),and(requester_profile_id.eq.$otherProfileId,target_profile_id.eq.$myProfileId)',
        );
    final list = (rows as List?) ?? const [];
    ContactRequestStatus? sent;
    ContactRequestStatus? received;
    for (final r in list) {
      final map = r as Map<String, dynamic>;
      final req = ContactRequest.fromMap(map);
      if (req.requesterProfileId == myProfileId) {
        sent = req.status;
      } else {
        received = req.status;
      }
      if (req.status == ContactRequestStatus.accepted) {
        return ContactHandshakeStatus.accepted;
      }
    }
    if (sent == ContactRequestStatus.pending) {
      return ContactHandshakeStatus.sentPending;
    }
    if (received == ContactRequestStatus.pending) {
      return ContactHandshakeStatus.receivedPending;
    }
    if (sent == ContactRequestStatus.declined ||
        received == ContactRequestStatus.declined) {
      return ContactHandshakeStatus.declined;
    }
    return ContactHandshakeStatus.none;
  }

  @override
  Future<List<ContactRequest>> listReceived(String myProfileId) async {
    final rows = await _db
        .from('contact_requests')
        .select()
        .eq('target_profile_id', myProfileId)
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((m) => ContactRequest.fromMap(m.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<ContactRequest>> listSent(String myProfileId) async {
    final rows = await _db
        .from('contact_requests')
        .select()
        .eq('requester_profile_id', myProfileId)
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((m) => ContactRequest.fromMap(m.cast<String, dynamic>()))
        .toList();
  }
}
