import '../../core/services/match_service.dart';
import '../../models/matrimonial_user.dart';
import 'package:http/http.dart' as http;

class HttpMatchService implements MatchService {
  final String baseUrl;
  HttpMatchService(http.Client _, {required this.baseUrl});

  Never _todo(String path) => throw UnimplementedError('Wire to $path');

  @override
  Future<List<MatrimonialUser>> getMutual(String userId) async =>
      _todo('/matches/mutual');

  @override
  Future<List<MatrimonialUser>> getSuggestions(String userId) async =>
      _todo('/matches/suggestions');
}
