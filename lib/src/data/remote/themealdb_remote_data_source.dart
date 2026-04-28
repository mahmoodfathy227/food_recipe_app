import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:food_app/src/config/app_config.dart';
import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/utils/utils.dart';

/// Public TheMealDB (no API key) — [https://www.themealdb.com/api.php](TheMealDB).
class TheMealDbRemoteDataSource {
  TheMealDbRemoteDataSource();

  FutureEither<List<RecipeSummary>> filterByCategory(String category) async {
    return _getFilter({'c': category});
  }

  FutureEither<List<RecipeSummary>> filterByArea(String area) async {
    return _getFilter({'a': area});
  }

  FutureEither<List<RecipeSummary>> search(String query) async {
    debugPrint('[TheMealDb] search s=$query');
    return _parseFilterResponse(() async {
      final res = await AppConfig.dio.get<Map<String, dynamic>>(
        'search.php',
        queryParameters: {'s': query},
      );
      return res;
    });
  }

  FutureEither<RecipeDetail?> lookupById(String id) async {
    try {
      debugPrint('[TheMealDb] lookup i=$id');
      final res = await AppConfig.dio.get<Map<String, dynamic>>(
        'lookup.php',
        queryParameters: {'i': id},
      );
      final data = res.data;
      if (data == null) {
        return right(null);
      }
      final list = data['meals'] as List<dynamic>?;
      if (list == null || list.isEmpty) {
        return right(null);
      }
      final m = list.first as Map<String, dynamic>;
      return right(RecipeDetail.fromJsonMap(m));
    } catch (e, st) {
      AppLogger.error('lookup $e', [e, st]);
      return left(ServerFailure('Lookup failed: $e', error: e));
    }
  }

  FutureEither<List<RecipeSummary>> _getFilter(Map<String, String> q) async {
    debugPrint('[TheMealDb] filter $q');
    return _parseFilterResponse(
      () => AppConfig.dio.get<Map<String, dynamic>>('filter.php', queryParameters: q),
    );
  }

  FutureEither<List<RecipeSummary>> _parseFilterResponse(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final res = await request();
      final data = res.data;
      if (data == null) {
        return right(<RecipeSummary>[]);
      }
      final list = data['meals'] as List<dynamic>?;
      if (list == null) {
        return right(<RecipeSummary>[]);
      }
      final out = <RecipeSummary>[];
      for (final item in list) {
        if (item is! Map) continue;
        out.add(RecipeSummary.fromJsonMap(item.cast<String, dynamic>()));
      }
      return right(out);
    } catch (e, st) {
      AppLogger.error('filter/parse $e', [e, st]);
      return left(ServerFailure('Request failed: $e', error: e));
    }
  }

  /// For notifications: one random(ish) recipe id from a category.
  FutureEither<String?> pickIdFromCategory(String category) async {
    final r = await filterByCategory(category);
    return r.map((list) {
      if (list.isEmpty) return null;
      return list.first.id;
    });
  }
}

/// Serializable bundle for last discovery (offline list + context text).
List<RecipeSummary> summaryListFromJsonString(String s) {
  final list = (jsonDecode(s) as List<dynamic>)
      .map((e) => RecipeSummary.fromJsonMap(e as Map<String, dynamic>))
      .toList();
  return list;
}

String summaryListToJsonString(List<RecipeSummary> list) {
  return jsonEncode(list.map((e) => e.toMap()).toList());
}
