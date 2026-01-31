import 'package:flutter/material.dart';
import 'package:oman_fe/features/home/domain/models/recipe_mock_data.dart';
import 'package:oman_fe/features/home/domain/enums/search_type.dart';
import '../../../../core/theme/app_colors.dart';


class HomeViewModel extends ChangeNotifier {
  SearchType _selectedType = SearchType.none;
  final TextEditingController searchController = TextEditingController();
  
  bool _isModalLoading = false;
  bool _isRealDataLoaded = false;
  bool _isResultVisible = false;
  bool _hasSelection = false;

  SearchType get selectedType => _selectedType;
  bool get isModalLoading => _isModalLoading;
  bool get isRealDataLoaded => _isRealDataLoaded;
  bool get isResultVisible => _isResultVisible;
  bool get hasSelection => _hasSelection;

  final List<String> _selectedIngredients = []; 
  List<String> _filteredCandidates = [];       
  final FocusNode searchFocusNode = FocusNode(); 

  HomeViewModel() {
    searchFocusNode.addListener(() {
      notifyListeners();
    });
  }

  List<String> get _allFlattenedIngredients {
  final data = RecipeMockData.kimchiStew;
  return [...data.essential, ...data.subIngredients, ...data.seasonings];
  }

  List<String> get selectedIngredients => _selectedIngredients;
  List<String> get filteredCandidates => _filteredCandidates;
  bool get isSearchFocused => searchFocusNode.hasFocus;

  List<String> get recentSearches => ["신김치", "돼지고기", "두부"];

  // 📍 화면 가장자리를 물들일 색상 (withValues alpha: 0.5)
  Color get glowColor {
    if (_selectedType == SearchType.none) return Colors.transparent;
    final baseColor = _selectedType == SearchType.ingredients 
        ? AppColors.primaryGreen 
        : AppColors.primaryOrange;
    return baseColor.withValues(alpha: 0.5);
  }

  bool get finalButtonVisible => _isResultVisible && _hasSelection && !_isModalLoading;

  void toggleType(SearchType type) {
    if (_selectedType != SearchType.none && _selectedType != type) {
      searchController.clear();
      _isResultVisible = false;
      _isRealDataLoaded = false;
    }
    _selectedType = (_selectedType == type) ? SearchType.none : type;
    notifyListeners();
  }

  void submitSearch(String value) {
  if (value.isEmpty) return;

  // 1. "재료" 모드일 때 -> 태그로 추가 (결과창 띄우기 X)
  if (_selectedType == SearchType.ingredients) {
    addIngredient(value); 
  } 
  // 2. "요리" 모드이거나 기타 상황 -> 실제 검색 결과 실행
  else {
    _triggerSearchResult();
  }
}

// [추가] 실제 검색 결과(모달)를 띄우는 로직을 분리
void _triggerSearchResult() {
  _isResultVisible = true;
  _isModalLoading = true;
  _isRealDataLoaded = false;
  notifyListeners();

  Future.delayed(const Duration(milliseconds: 1200), () {
    _isModalLoading = false;
    _isRealDataLoaded = true;
    notifyListeners();
  });
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
    if (text.isEmpty) {
      _filteredCandidates = [];
    } else {
      // 입력값 포함 여부 확인 & 중복 선택 방지
      _filteredCandidates = _allFlattenedIngredients
          .where((item) => item.contains(text) && !_selectedIngredients.contains(item))
          .toSet().toList(); 
    }
    notifyListeners();
  }

  void addIngredient(String name) {
    if (!_selectedIngredients.contains(name)) {
      _selectedIngredients.add(name);
      searchController.clear(); 
      _filteredCandidates = []; 
      notifyListeners();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        searchFocusNode.requestFocus();
      });
    }
  }
  
  void removeIngredient(String name) {
    _selectedIngredients.remove(name);
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
  searchFocusNode.dispose(); // 추가
  super.dispose();
}
}