import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/match_model.dart';

class MatchApiService {
  Future<List<MatchModel>> getMatches({int size = 20}) async {
    try {
      final resp = await DioClient.get(
        ApiConstants.matches,
        queryParameters: {'size': size},
      );

      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return [];
      }

      final list = json['data'] as List<dynamic>?;
      if (list == null) return [];

      return list.map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
