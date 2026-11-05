import '../../shared/models/contact_request.dart';

/// Contact exchange handshake service abstracts backend differences.
/// Contract:
/// - request: current user requests other user's contact.
/// - accept/decline: current user responds to a received request.
/// - status: consolidated status between two users.
/// - list: pending received/sent requests for current user.
abstract class ContactExchangeService {
  Future<String> request(String requesterProfileId, String targetProfileId);

  Future<void> accept(String myProfileId, String requesterProfileId);

  Future<void> decline(String myProfileId, String requesterProfileId);

  Future<ContactHandshakeStatus> getStatus(
    String myProfileId,
    String otherProfileId,
  );

  Future<List<ContactRequest>> listReceived(String myProfileId);

  Future<List<ContactRequest>> listSent(String myProfileId);
}
