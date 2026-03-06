import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/api_constants.dart';
import '../models/recipe_models.dart';

class SearchApiService {
  final Dio _dio; 

  SearchApiService(this._dio);

  // 최근 검색어 조회 (타입별: INGREDIENT, RECIPE)
  Future<List<IngredientSimpleDto>> getRecentSearches(String type) async {
    try {
      final response = await _dio.get(
        ApiConstants.searchHistory, // 하드코딩된 URL 대신 상수 사용
        queryParameters: {'type': type},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data as List).map((e) {
          final id = e['id'] ?? e['keywordId'] ?? 0;
          final name = e['name'] ?? e['keyword'] ?? '';
          return IngredientSimpleDto(id: id, name: name);
        }).toList();

        // 빈 문자열 방어 코드
        return list.where((item) => item.name.trim().isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SearchApiService] 최근 검색어 로드 실패 ($type): $e');
      return [];
    }
  }

  // 최근 검색어 저장
  Future<void> saveRecentSearch(String type, int? keywordId, String keyword) async {
    try {
      await _dio.post(
        ApiConstants.searchHistory,
        data: {
          'type': type,
          'keywordId': keywordId,
          'keyword': keyword,
        },
      );
    } catch (e) {
      debugPrint('[SearchApiService] 최근 검색어 저장 실패: $e');
    }
  }

  // 최근 검색어 삭제
  Future<void> deleteRecentSearch(String type, int? keywordId, String keyword) async {
    try {
      await _dio.delete(
        ApiConstants.searchHistory,
        data: {
          'type': type,
          'keywordId': keywordId,
          'keyword': keyword,
        },
      );
    } catch (e) {
      debugPrint('[SearchApiService] 최근 검색어 삭제 실패: $e');
    }
  }
}