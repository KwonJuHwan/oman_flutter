class CulinaryIngredientResponse {
  final int ingredientId;
  final String ingredientName;
  final int totalVideoCount;
  final int ingredientIncludedVideoCount;
  final double percentage;

  CulinaryIngredientResponse({
    required this.ingredientId,
    required this.ingredientName,
    required this.totalVideoCount,
    required this.ingredientIncludedVideoCount,
    required this.percentage,
  });

  factory CulinaryIngredientResponse.fromJson(Map<String, dynamic> json) {
    return CulinaryIngredientResponse(
      ingredientId: json['ingredientId'] ?? 0,
      ingredientName: json['ingredientName'] ?? '',
      totalVideoCount: json['totalVideoCount'] ?? 0,
      ingredientIncludedVideoCount: json['ingredientIncludedVideoCount'] ?? 0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
    );
  }
}

class CulinaryIngredientGroupResponse {
  final List<CulinaryIngredientResponse> mainIngredients;
  final List<CulinaryIngredientResponse> subIngredients;
  final List<CulinaryIngredientResponse> otherIngredients;

  CulinaryIngredientGroupResponse({
    required this.mainIngredients,
    required this.subIngredients,
    required this.otherIngredients,
  });

  factory CulinaryIngredientGroupResponse.fromJson(Map<String, dynamic> json) {
    return CulinaryIngredientGroupResponse(
      mainIngredients: (json['mainIngredients'] as List<dynamic>?)
              ?.map((e) => CulinaryIngredientResponse.fromJson(e))
              .toList() ?? [],
      subIngredients: (json['subIngredients'] as List<dynamic>?)
              ?.map((e) => CulinaryIngredientResponse.fromJson(e))
              .toList() ?? [],
      otherIngredients: (json['otherIngredients'] as List<dynamic>?)
              ?.map((e) => CulinaryIngredientResponse.fromJson(e))
              .toList() ?? [],
    );
  }
}

class IngredientSimpleDto {
  final int id;
  final String name;

  IngredientSimpleDto({required this.id, required this.name});

  factory IngredientSimpleDto.fromJson(Map<String, dynamic> json) {
    return IngredientSimpleDto(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientSimpleDto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CulinaryRecommendationDto {
  final String name;
  final String status; // 백엔드에서 주는 상태값 (예: MATCH, INSUFFICIENT, SURPLUS 등)
  final List<IngredientSimpleDto> ingredients;

  CulinaryRecommendationDto({
    required this.name,
    required this.status,
    required this.ingredients,
  });

  factory CulinaryRecommendationDto.fromJson(Map<String, dynamic> json) {
    return CulinaryRecommendationDto(
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => IngredientSimpleDto.fromJson(e))
              .toList() ?? [],
    );
  }
}