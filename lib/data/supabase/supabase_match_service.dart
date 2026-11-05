import '../../core/services/match_service.dart';
import '../../models/matrimonial_user.dart';
import '../../services/matrimonial_service.dart' as legacy;

class SupabaseMatchService implements MatchService {
  @override
  Future<List<MatrimonialUser>> getMutual(String userId) =>
      legacy.MatrimonialService.getAcceptedConnections(userId);

  @override
  Future<List<MatrimonialUser>> getSuggestions(String userId) =>
      legacy.MatrimonialService.getMatches(userId);
}
