import '../../shared/models/icebreaker.dart';

abstract class IcebreakerService {
  Future<List<Icebreaker>> list({bool activeOnly = true});
}
