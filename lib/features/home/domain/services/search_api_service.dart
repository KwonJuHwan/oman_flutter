import 'package:dio/dio.dart';
import '../../domain/models/recipe_models.dart';
import '../../../../core/config/api_constants.dart';

class SearchApiService {
  final Dio _dio; 

  SearchApiService(this._dio);

  Future<List<IngredientSimpleDto>> getRecentSearches(String type) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/v1/search-history',
        queryParameters: {'type': type},
      );
      return (response.data as List)
          .map((json) => IngredientSimpleDto.fromJson(json))
          .toList();
    } catch (e) {
      print('최근 검색어 로드 실패: $e');
      return [];
    }
  }

  Future<void> saveRecentSearch(String type, IngredientSimpleDto item) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}/api/v1/search-history',
        data: {
          'type': type,
          'keywordId': item.id,
          'keyword': item.name,
        },
      );
    } catch (e) {
      print('검색어 저장 실패: $e');
    }
  }

  Future<void> deleteRecentSearch(String type, IngredientSimpleDto item) async {
    try {
      await _dio.delete(
        '${ApiConstants.baseUrl}/api/v1/search-history',
        data: {
          'type': type,
          'keywordId': item.id,
          'keyword': item.name,
        },
      );
    } catch (e) {
      print('검색어 삭제 실패: $e');
    }
  }
}