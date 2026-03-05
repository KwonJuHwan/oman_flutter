import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../../../../core/network/token_interceptor.dart';

import 'package:oman_fe/features/home/domain/repositories/recipe_repository.dart';
import 'package:oman_fe/features/home/domain/models/recipe_models.dart';
import 'package:oman_fe/features/home/domain/enums/search_type.dart';
import '../../../../core/theme/app_colors.dart';

class HomeViewModel extends ChangeNotifier {
  SearchType _selectedType = SearchType.none;
  final TextEditingController searchController = TextEditingController();
  
  bool _isModalLoading = false;
  bool _isRealDataLoaded = false;
  bool _isResultVisible = false;
  bool _hasSelection = false;
  String? _selectedDishName;
  
  String? get selectedDishName => _selectedDishName;
  SearchType get selectedType => _selectedType;
  bool get isModalLoading => _isModalLoading;
  bool get isRealDataLoaded => _isRealDataLoaded;
  bool get isResultVisible => _isResultVisible;
  bool get hasSelection => _hasSelection;

  final List<IngredientSimpleDto> _selectedIngredients = []; 
  List<IngredientSimpleDto> _filteredCandidates = [];   
  
  List<IngredientSimpleDto> _recentIngredientSearches = [];
  List<IngredientSimpleDto> _recentRecipeSearches = [];

  final FocusNode searchFocusNode = FocusNode(); 
  Timer? _debounce;

  CulinaryIngredientGroupResponse? recipeDetailData;
  List<CulinaryRecommendationDto> ingredientSearchResults = [];
  
  late final RecipeRepository _repository;

  HomeViewModel() {
    final dio = Dio();
    dio.interceptors.add(TokenInterceptor(dio));
    _repository = RecipeRepository(dio);

    _loadRecentSearches();

    searchFocusNode.addListener(() {
      notifyListeners();
    });
  }

  List<IngredientSimpleDto> get selectedIngredients => _selectedIngredients;
  List<int> get selectedIngredientIds => _selectedIngredients.map((e) => e.id!).toList(); // id가 반드시 있다고 가정

  List<IngredientSimpleDto> get filteredCandidates => _filteredCandidates;
  
  List<IngredientSimpleDto> get recentIngredientSearches => _recentIngredientSearches;
  List<IngredientSimpleDto> get recentRecipeSearches => _recentRecipeSearches;
  
  bool get isSearchFocused => searchFocusNode.hasFocus;

  Color get glowColor {
    if (_selectedType == SearchType.none) return Colors.transparent;
    final baseColor = _selectedType == SearchType.ingredients 
        ? AppColors.primaryGreen 
        : AppColors.primaryOrange;
    return baseColor.withValues(alpha: 0.5); 
  }

  Future<void> _loadRecentSearches() async {
    _recentIngredientSearches = await _repository.getRecentIngredientSearches();
    _recentRecipeSearches = await _repository.getRecentRecipeSearches();
    notifyListeners();
  }


  Future<void> removeRecentSearch(IngredientSimpleDto item) async {
    final String typeStr = _selectedType == SearchType.ingredients ? 'INGREDIENT' : 'RECIPE';
    
    if (_selectedType == SearchType.ingredients) {
      _recentIngredientSearches.removeWhere((e) => e.name == item.name);
    } else {
      _recentRecipeSearches.removeWhere((e) => e.name == item.name);
    }
    notifyListeners();

    try {
      await _repository.deleteRecentSearch(typeStr, item.id, item.name);
    } catch (e) {
      print("최근 검색어 삭제 실패: $e");
     
    }
  }

  bool get finalButtonVisible {
    if (!_isResultVisible || _isModalLoading) return false;

    if (_selectedType == SearchType.ingredients) {
      return _selectedDishName != null;
    } else {
      return _hasSelection;
    }
  }

  void toggleDishSelection(String dishName) {
    if (_selectedDishName == dishName) {
      _selectedDishName = null; 
    } else {
      _selectedDishName = dishName;
    }
    notifyListeners();
  }

  Future<void> toggleType(SearchType type) async {
    if (_selectedType != SearchType.none && _selectedType != type) {
      searchController.clear();
      _isResultVisible = false;
      _isRealDataLoaded = false;

      if (_selectedIngredients.isNotEmpty) {
        final int count = _selectedIngredients.length;
        for (int i = count - 1; i >= 0; i--) {
          _selectedIngredients.removeAt(i);
          notifyListeners(); 
          await Future.delayed(const Duration(milliseconds: 50)); 
        }
      }
    }
    
    _selectedType = (_selectedType == type) ? SearchType.none : type;
    notifyListeners();
  }

  Future<void> submitSearch(String value) async {
    if (_selectedType == SearchType.ingredients) {
      if (value.isNotEmpty) {
        final IngredientSimpleDto? matchedDto = _filteredCandidates
            .where((dto) => dto.name == value.trim())
            .firstOrNull;

        if (matchedDto != null) {
          await addIngredient(matchedDto); 
        } else {
          searchController.clear(); 
        }
      } 
    
      if (_selectedIngredients.isNotEmpty) {
        await _triggerSearchResult(); 
      }
    } 
    else if (_selectedType == SearchType.recipe) {
      if (value.isNotEmpty) {
        await _triggerSearchResult(); 
      }
    }
  }

  Future<void> _triggerSearchResult() async {
    _isResultVisible = true;
    _isModalLoading = true;
    _isRealDataLoaded = false;
    
    _hasSelection = false; 
    _selectedDishName = null; 
    
    notifyListeners();

    try {
      if (_selectedType == SearchType.recipe) {
        final String recipeName = searchController.text;
        
        await _repository.saveRecentSearch("RECIPE", null, recipeName);
        await _loadRecentSearches(); 

        final result = await _repository.getIngredientStatistics(recipeName);
        if (result != null) {
          recipeDetailData = result;
          _selectedDishName = recipeName; 
        }
      } else if (_selectedType == SearchType.ingredients) {
        final result = await _repository.getCulinaryRecommendations(selectedIngredientIds);
        ingredientSearchResults = result;
      }
    } catch (e) {
      print("검색 데이터 로드 에러: $e");
    } finally {
      _isModalLoading = false;
      _isRealDataLoaded = true;
      notifyListeners();
    }
  }

  void updateSelection(bool has) {
    _hasSelection = has;
    notifyListeners();
  }

  void setResultVisible(bool visible) {
    _isResultVisible = visible;
    notifyListeners();
  }

  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (text.isEmpty) {
      _filteredCandidates = [];
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _repository.getAutocomplete(text);
      _filteredCandidates = results.where((item) => !_selectedIngredients.contains(item)).toList();
      notifyListeners();
    });
  }

  Future<void> addIngredient(IngredientSimpleDto ingredient) async {
    if (!_selectedIngredients.contains(ingredient)) {
      _selectedIngredients.add(ingredient);
      searchController.clear(); 
      _filteredCandidates = []; 
      notifyListeners();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchFocusNode.requestFocus();
      });

      await _repository.saveRecentSearch("INGREDIENT", ingredient.id, ingredient.name);
      await _loadRecentSearches(); 
    }
  }
  
  void removeIngredient(IngredientSimpleDto ingredient) {
    _selectedIngredients.remove(ingredient);
    notifyListeners();
  }

  void resetSearch() {
    searchController.clear();
    _isResultVisible = false;
    _isRealDataLoaded = false;
    _selectedType = SearchType.none;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose(); 
    _debounce?.cancel();
    super.dispose();
  }
}