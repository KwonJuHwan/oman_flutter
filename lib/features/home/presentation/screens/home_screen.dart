import 'package:flutter/material.dart';
import 'package:oman_fe/features/home/domain/services/search_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart'; 
import '../../domain/enums/search_type.dart';
import '../../domain/repositories/recipe_repository.dart';

import '../state/home_viewmodel.dart';
import '../widgets/animations/bounce_wrapper.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/home_category_button.dart';
import '../widgets/home/search_suggestions_box.dart';
import '../widgets/home/floating_search_button.dart';
import '../widgets/recipe/recipe_report_sheet.dart';
import '../widgets/youtube/yotube_recommendation_layer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _vm;
  final GlobalKey<SequentialBounceWrapperState> _leftKey = GlobalKey();
  final GlobalKey<SequentialBounceWrapperState> _rightKey = GlobalKey();
  
  bool _isYoutubeLayerActive = false;
  bool _isButtonSlidingDown = false; 
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel(recipeRepository: getIt<RecipeRepository>() , searchApiService: getIt<SearchApiService>());
    _vm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _handleFloatingButtonTap() async {
    setState(() => _isButtonPressed = true);
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => _isButtonPressed = false);
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => _isButtonSlidingDown = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isYoutubeLayerActive = true;
        _isButtonSlidingDown = false; 
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double sheetHeight = screenHeight * 0.7;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: screenWidth, height: screenHeight,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center, radius: 1.3,
                colors: [Colors.transparent, _vm.glowColor],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _vm.setResultVisible(false),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            bottom: false,
            child: Stack(children: [_buildMainUI(screenHeight)]),
          ),
          
          _buildResultLayer(sheetHeight),
          
          if (_isYoutubeLayerActive)
            YoutubeRecommendationLayer(
              repository: getIt<RecipeRepository>(),
              culinaryName: _vm.selectedDishName ?? "김치찌개", 
              ingredientIds: _vm.selectedIngredientIds, 
              onClose: () => setState(() => _isYoutubeLayerActive = false),
            ),
            
          if (!_isYoutubeLayerActive)
            FloatingSearchButton(
              isVisible: _vm.finalButtonVisible,
              isSlidingDown: _isButtonSlidingDown,
              isPressed: _isButtonPressed,
              onTap: _handleFloatingButtonTap,
            ),
        ],
      ),
    );
  }

  Widget _buildMainUI(double screenHeight) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
      top: _vm.isResultVisible ? 40 : screenHeight * 0.22,
      left: 24, right: 24,
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 220),
          const SizedBox(height: 40),
          HomeSearchBar(
            vm: _vm,
            selectedType: _vm.selectedType,
            controller: _vm.searchController,
            onClear: _vm.resetSearch,
            onSubmitted: _vm.submitSearch,
            onDisabledTap: () {
              _leftKey.currentState?.play();
              _rightKey.currentState?.play();
            },
          ),
          
          SearchSuggestionsBox(vm: _vm), 
          
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SequentialBounceWrapper(
                key: _leftKey, isLeft: true,
                child: HomeCategoryButton(
                  type: SearchType.ingredients, label: "재료", icon: Icons.eco_rounded,
                  baseColor: AppColors.primaryGreen,
                  isSelected: _vm.selectedType == SearchType.ingredients,
                  onTap: () => _vm.toggleType(SearchType.ingredients),
                ),
              ),
              const SizedBox(width: 12),
              SequentialBounceWrapper(
                key: _rightKey, isLeft: false,
                child: HomeCategoryButton(
                  type: SearchType.recipe, label: "요리", icon: Icons.soup_kitchen_rounded,
                  baseColor: AppColors.primaryOrange,
                  isSelected: _vm.selectedType == SearchType.recipe,
                  onTap: () => _vm.toggleType(SearchType.recipe),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultLayer(double sheetHeight) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      bottom: _vm.isResultVisible ? 0 : -(sheetHeight - 80.0),
      left: 0, right: 0, height: sheetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -5) _vm.setResultVisible(true);
          if (details.delta.dy > 5) _vm.setResultVisible(false);
        },
        child: RecipeReportSheet(
          isLoading: _vm.isModalLoading,
          isResultVisible: _vm.isRealDataLoaded,
          isIngredientSearch: _vm.selectedType == SearchType.ingredients,
          selectedDishName: _vm.selectedDishName,
          onDishSelected: (dishName) => _vm.toggleDishSelection(dishName),
          onSelectionChanged: (hasSelection) => _vm.updateSelection(hasSelection),
          recipeDetailData: _vm.recipeDetailData,
          ingredientResults: _vm.ingredientSearchResults,
        ),
      ),
    );
  }
}