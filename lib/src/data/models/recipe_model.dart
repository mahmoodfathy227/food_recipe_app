import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Lightweight row from TheMealDB `filter` / `search` results.
class RecipeSummary extends Equatable {
  final String id;
  final String name;
  final String? thumbUrl;
  final String? category;
  final String? area;

  const RecipeSummary({
    required this.id,
    required this.name,
    this.thumbUrl,
    this.category,
    this.area,
  });

  factory RecipeSummary.fromJsonMap(Map<String, dynamic> json) {
    return RecipeSummary(
      id: (json['idMeal'] ?? json['id'] ?? '') as String,
      name: (json['strMeal'] ?? json['name'] ?? '') as String,
      thumbUrl: json['strMealThumb'] as String?,
      category: json['strCategory'] as String?,
      area: json['strArea'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'strMeal': name,
        'idMeal': id,
        'strMealThumb': thumbUrl,
        'strCategory': category,
        'strArea': area,
      };

  @override
  List<Object?> get props => [id, name, thumbUrl, category, area];
}

/// Full meal from TheMealDB `lookup` (for offline we persist this JSON string).
class RecipeDetail extends Equatable {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? thumbUrl;
  final String? instructions;
  final List<IngredientLine> ingredients;

  const RecipeDetail({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.thumbUrl,
    this.instructions,
    this.ingredients = const [],
  });

  factory RecipeDetail.fromJsonMap(Map<String, dynamic> json) {
    final List<IngredientLine> lines = [];
    for (var i = 1; i <= 20; i++) {
      final ing = json['strIngredient$i'] as String?;
      final m = json['strMeasure$i'] as String?;
      if (ing != null && ing.trim().isNotEmpty) {
        lines.add(IngredientLine(ingredient: ing.trim(), measure: m?.trim()));
      }
    }
    return RecipeDetail(
      id: (json['idMeal'] ?? '') as String,
      name: (json['strMeal'] ?? '') as String,
      category: json['strCategory'] as String?,
      area: json['strArea'] as String?,
      thumbUrl: json['strMealThumb'] as String?,
      instructions: json['strInstructions'] as String?,
      ingredients: lines,
    );
  }

  Map<String, dynamic> toFullJsonMap() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strCategory': category,
      'strArea': area,
      'strMealThumb': thumbUrl,
      'strInstructions': instructions,
      for (var i = 0; i < ingredients.length; i++) ...{
        'strIngredient${i + 1}': ingredients[i].ingredient,
        'strMeasure${i + 1}': ingredients[i].measure,
      },
    };
  }

  String toJsonString() => jsonEncode(toFullJsonMap());

  @override
  List<Object?> get props => [id, name, category, area, thumbUrl, instructions, ingredients];
}

class IngredientLine extends Equatable {
  final String ingredient;
  final String? measure;

  const IngredientLine({required this.ingredient, this.measure});

  @override
  List<Object?> get props => [ingredient, measure];
}
