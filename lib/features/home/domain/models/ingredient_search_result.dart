enum IngredientMatchStatus { match, insufficient, surplus }

class IngredientSearchResult {
  final String dishName;
  final IngredientMatchStatus status;
  final List<String> targetIngredients;

  IngredientSearchResult({
    required this.dishName,
    required this.status,
    required this.targetIngredients,
  });
}