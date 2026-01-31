// lib/features/home/domain/models/recipe_mock_data.dart

class IngredientItem {
  final String name;
  final String category; // 필수, 부재료, 양념 등

  IngredientItem({required this.name, required this.category});
}

class RecipeMockData {
  final String dishName;
  final List<String> essential;
  final List<String> subIngredients;
  final List<String> seasonings;

  RecipeMockData({
    required this.dishName,
    required this.essential,
    required this.subIngredients,
    required this.seasonings,
  });

  // 김치찌개 데이터 싱글톤 혹은 정적 생성자
  static final RecipeMockData kimchiStew = RecipeMockData(
    dishName: "김치찌개",
    essential: ["신김치", "돼지고기", "두부", "대파", "양파", "쌀뜨물", "테스트", "테스트2","테스트3","테스트3","테스트3","테스트3","테스트3","테스트3"],
    subIngredients: ["청양고추", "느타리버섯", "스팸", "당면 사리", "참치캔", "만두"],
    seasonings: ["고춧가루", "국간장", "다진 마늘", "멸치액젓", "설탕", "후추", "된장"],
  );
}