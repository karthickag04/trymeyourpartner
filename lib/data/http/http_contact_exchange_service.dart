import '../../core/services/contact_exchange_service.dart';
import '../../shared/models/contact_request.dart';
import 'http_client.dart';

class HttpContactExchangeService implements ContactExchangeService {
  final ApiClient _api;
  HttpContactExchangeService(this._api);

  @override
  Future<String> request(
    String requesterProfileId,
    String targetProfileId,
  ) async {
    final res = await _api.post(
      '/contacts/requests',
      body: {
        'requester_profile_id': requesterProfileId,
        'target_profile_id': targetProfileId,
      },
    );
    if (res is Map && res['id'] != null) return res['id'].toString();
    return '';
  }

  @override
  Future<void> accept(String myProfileId, String requesterProfileId) async {
    await _api.post(
      '/contacts/requests/accept',
      body: {'requester_profile_id': requesterProfileId},
    );
  }

  @override
  Future<void> decline(String myProfileId, String requesterProfileId) async {
    await _api.post(
      '/contacts/requests/decline',
      body: {'requester_profile_id': requesterProfileId},
    );
  }

  @override
  Future<ContactHandshakeStatus> getStatus(
    String myProfileId,
    String otherProfileId,
  ) async {
    final res = await _api.get(
      '/contacts/requests/status',
      query: {'my_profile_id': myProfileId, 'other_profile_id': otherProfileId},
    );
    final s = (res is Map ? res['status'] : res)?.toString().toLowerCase();
    switch (s) {
      case 'accepted':
        return ContactHandshakeStatus.accepted;
      case 'sent_pending':
        return ContactHandshakeStatus.sentPending;
      case 'received_pending':
        return ContactHandshakeStatus.receivedPending;
      case 'declined':
        return ContactHandshakeStatus.declined;
      case 'cancelled':
        return ContactHandshakeStatus.cancelled;
      default:
        return ContactHandshakeStatus.none;
    }
  }

  List<ContactRequest> _fromList(dynamic res) {
    final items = (res is Map && res['items'] is List)
        ? res['items'] as List
        : (res is List ? res : const []);
    return items
        .whereType<Map>()
        .map(
          (m) => ContactRequest.fromMap(
            m.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList();
  }

  @override
  Future<List<ContactRequest>> listReceived(String myProfileId) async {
    final res = await _api.get('/contacts/requests/received');
    return _fromList(res);
  }

  @override
  Future<List<ContactRequest>> listSent(String myProfileId) async {
    final res = await _api.get('/contacts/requests/sent');
    return _fromList(res);
  }
}
