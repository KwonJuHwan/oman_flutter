import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/api_constants.dart';
import '../models/video_recommendation_model.dart';
import '../models/recipe_models.dart';

class RecipeRepository {
  final Dio _dio;

  RecipeRepository(this._dio);

  // 요리별 재료 통계 정보 조회 
  Future<CulinaryIngredientGroupResponse?> getIngredientStatistics(String culinaryName) async {
    try {
      final response = await _dio.get(
        ApiConstants.culinaryStatistics, 
        queryParameters: {'name': culinaryName},
      );
      if (response.statusCode == 200 && response.data != null) {
        return CulinaryIngredientGroupResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('[RecipeRepository] 요리 통계 조회 실패: $e');
      return null;
    }
  }

  // 재료 리스트 기반 다중 요리 추천
  Future<List<CulinaryRecommendationDto>> getCulinaryRecommendations(List<int> ingredientIds) async {
    try {
      final response = await _dio.post(
        ApiConstants.culinaryRecommendations, 
        data: {'ingredientIds': ingredientIds},
      );
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List<dynamic>)
            .map((e) => CulinaryRecommendationDto.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[RecipeRepository] 요리 추천 조회 실패: $e');
      return [];
    }
  }

  // 특정 요리에 대한 상세 영상 추천
  Future<VideoRecommendationResponseDto?> getRecommendedVideos({
    required String culinaryName,
    required List<int> ingredientIds,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.videoRecommendations(culinaryName),
        data: {"ingredientIds": ingredientIds},
      );

      if (response.statusCode == 200 && response.data != null) {
        return VideoRecommendationResponseDto.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('[RecipeRepository] 영상 추천 데이터 로드 실패: $e');
      return null;
    }
  }

  //  재료/요리 자동완성
  Future<List<IngredientSimpleDto>> getAutocomplete(String keyword) async {
    try {
      final response = await _dio.get(
        ApiConstants.autocomplete, 
        queryParameters: {'keyword': keyword}
      );
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List).map((e) => IngredientSimpleDto.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[RecipeRepository] 자동완성 에러: $e');
      return [];
    }
  }
}