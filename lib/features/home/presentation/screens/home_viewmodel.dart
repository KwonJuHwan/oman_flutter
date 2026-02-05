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
  String? _selectedDishName;
  
  String? get selectedDishName => _selectedDishName;
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
  List<String> get recentRecipeSearches => ["김치찌개", "된장찌개", "계란말이", "제육볶음"];

  // 📍 화면 가장자리를 물들일 색상 (withValues alpha: 0.5)
  Color get glowColor {
    if (_selectedType == SearchType.none) return Colors.transparent;
    final baseColor = _selectedType == SearchType.ingredients 
        ? AppColors.primaryGreen 
        : AppColors.primaryOrange;
    return baseColor.withValues(alpha: 0.5);
  }

  bool get finalButtonVisible {
  // 공통 조건: 결과창이 떠있고 로딩 중이 아닐 때
  if (!_isResultVisible || _isModalLoading) return false;

  if (_selectedType == SearchType.ingredients) {
    // 1. 재료 검색 모드: 요리 카드(_selectedDishName)가 선택되었을 때 활성화
    return _selectedDishName != null;
  } else {
    // 2. 요리 검색 모드: 재료 칩(_hasSelection)이 하나라도 선택되었을 때 활성화
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

  void submitSearch(String value) {
  //  재료 모드일 때 로직 분기
  if (_selectedType == SearchType.ingredients) {
    if (value.isNotEmpty) {
      addIngredient(value); 
    } else if (_selectedIngredients.isNotEmpty) {
      _triggerSearchResult(); 
    }
  } else if (_selectedType == SearchType.recipe) {
    if (value.isNotEmpty) {
      _triggerSearchResult(); 
    }
  }
}


void _triggerSearchResult() {
    _isResultVisible = true;
    _isModalLoading = true;
    _isRealDataLoaded = false;
    
    _hasSelection = false; 
    _selectedDishName = null; // ✨ 요리 선택 초기화
    
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