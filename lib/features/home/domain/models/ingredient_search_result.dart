enum IngredientMatchStatus { match, insufficient, surplus }

class IngredientSearchResult {
  final String dishName;
  final IngredientMatchStatus status;
  final List<String> targetIngredients; // 부족하거나 남은 재료 리스트

  IngredientSearchResult({
    required this.dishName,
    required this.status,
    required this.targetIngredients,
  });
}