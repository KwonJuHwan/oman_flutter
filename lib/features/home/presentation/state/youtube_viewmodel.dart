import 'package:flutter/material.dart';
import '../../domain/models/video_recommendation_model.dart';
import '../../domain/repositories/recipe_repository.dart';

class YoutubeViewModel extends ChangeNotifier {
  final RecipeRepository _repository;
  
  bool _isLoading = true;
  VideoRecommendationResponseDto? _videoData;

  bool get isLoading => _isLoading;
  VideoRecommendationResponseDto? get videoData => _videoData;

  YoutubeViewModel({required RecipeRepository repository}) : _repository = repository;

  Future<void> fetchVideoData({required String culinaryName, required List<int> ingredientIds}) async {
    _isLoading = true;
    notifyListeners();

    final data = await _repository.getRecommendedVideos(
      culinaryName: culinaryName,
      ingredientIds: ingredientIds,
    );

    _videoData = data;
    _isLoading = false;
    notifyListeners();
  }
}