// lib/features/home/domain/repositories/recipe_repository.dart

import 'package:dio/dio.dart';
import '../../../../core/config/api_constants.dart';
import '../models/video_recommendation_model.dart';
import '../models/recipe_models.dart';

class RecipeRepository {
  final Dio _dio;

  // TokenInterceptor가 적용된 Dio 객체를 주입받거나 내부에서 생성합니다.
  RecipeRepository(this._dio);

  //  요리별 재료 통계 정보 조회 
  Future<CulinaryIngredientGroupResponse?> getIngredientStatistics(String culinaryName) async {
    try {
      final response = await _dio.get(
        ApiConstants.culinaryStatistics, // ApiConstants에 추가 필요: '$baseUrl/recipes/culinary'
        queryParameters: {'name': culinaryName},
      );
      if (response.statusCode == 200 && response.data != null) {
        return CulinaryIngredientGroupResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('요리 통계 조회 실패: $e');
      return null;
    }
  }

  //  재료 리스트 기반 다중 요리 추천 (재료 검색 모드)
  Future<List<CulinaryRecommendationDto>> getCulinaryRecommendations(List<int> ingredientIds) async {
    try {
      final response = await _dio.post(
        ApiConstants.culinaryRecommendations, // ApiConstants에 추가 필요: '$baseUrl/recipes/recommendations'
        data: {'ingredientIds': ingredientIds},
      );
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List<dynamic>)
            .map((e) => CulinaryRecommendationDto.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('요리 추천 조회 실패: $e');
      return [];
    }
  }

  /// 특정 요리에 대한 상세 영상 추천 API 호출
  Future<VideoRecommendationResponseDto?> getRecommendedVideos({
    required String culinaryName,
    required List<int> ingredientIds,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.videoRecommendations(culinaryName),
        data: {
          // 백엔드의 IngredientRequest 레코드 형식에 맞춤
          "ingredientIds": ingredientIds,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return VideoRecommendationResponseDto.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('영상 추천 데이터 로드 실패: $e');
      return null;
    }
  }
  //  자동완성 API
  Future<List<IngredientSimpleDto>> getAutocomplete(String keyword) async {
    try {
      final response = await _dio.get(ApiConstants.autocomplete, queryParameters: {'keyword': keyword});
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List).map((e) => IngredientSimpleDto.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('자동완성 에러: $e');
      return [];
    }
  }

  // 최근 검색어 조회 API
  Future<List<IngredientSimpleDto>> getRecentIngredientSearches() async {
    try {

      final response = await _dio.get(
        ApiConstants.searchHistory, 
        queryParameters: {'type': 'INGREDIENT'} 
      );
      

      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data as List).map((e) {
          final id = e['id'] ?? e['keywordId'] ?? 0;
          final name = e['name'] ?? e['keyword'] ?? '';
          return IngredientSimpleDto(id: id, name: name);
        }).toList();

        final filteredList = list.where((item) => item.name.trim().isNotEmpty).toList();
        
        return filteredList;
      }
    } catch (e) {
      print('[로그 - Repo] 재료 최근검색 에러: $e');
    }
    return [];
  }

  Future<List<IngredientSimpleDto>> getRecentRecipeSearches() async {
    try {

      final response = await _dio.get(
        ApiConstants.searchHistory, 
        queryParameters: {'type': 'RECIPE'} 
      );
      

      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data as List).map((e) {
          final id = e['id'] ?? e['keywordId'] ?? 0;
          final name = e['name'] ?? e['keyword'] ?? '';
          return IngredientSimpleDto(id: id, name: name);
        }).toList();

        final filteredList = list.where((item) => item.name.trim().isNotEmpty).toList();
        
        return filteredList;
      }
    } catch (e) {
      print('[로그 - Repo] 재료 최근검색 에러: $e');
    }
    return [];
  }

  //  최근 검색어 저장 API 
  Future<void> saveRecentSearch(String type, int? keywordId, String keyword) async {
    try {
      await _dio.post(ApiConstants.searchHistory, data: {
        'type': type, 
        'keywordId': keywordId,
        'keyword': keyword
      });
    } catch (e) {
      print('최근 검색어 저장 에러: $e');
    }
  }

  // 최근 검색어 삭제 API
  Future<void> deleteRecentSearch(String type, int? keywordId, String keyword) async {
    try {
      // Dio의 delete는 data를 Body에 담아 보낼 수 있습니다.
      await _dio.delete(ApiConstants.searchHistory, data: {
        'type': type,
        'keywordId': keywordId,
        'keyword': keyword
      });
    } catch (e) {
      print('최근 검색어 삭제 에러: $e');
    }
  }
}