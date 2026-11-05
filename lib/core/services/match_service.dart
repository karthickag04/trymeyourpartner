import '../../models/matrimonial_user.dart';

abstract class MatchService {
  Future<List<MatrimonialUser>> getSuggestions(String userId);
  Future<List<MatrimonialUser>> getMutual(String userId);
}
