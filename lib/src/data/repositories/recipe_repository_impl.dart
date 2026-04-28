import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:food_app/src/data/local/recipe_local_data_source.dart';
import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/data/remote/themealdb_remote_data_source.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/services/internet_connection_service.dart';
import 'package:food_app/src/services/location_context_service.dart';
import 'package:food_app/src/utils/failure.dart';
import 'package:food_app/src/utils/meal_time_context.dart';
import 'package:food_app/src/utils/typedefs.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl({
    TheMealDbRemoteDataSource? remote,
    RecipeLocalDataSource? local,
    InternetConnectionService? net,
  })  : _remote = remote ?? TheMealDbRemoteDataSource(),
        _local = local ?? RecipeLocalDataSource(),
        _net = net ?? InternetConnectionService();

  final TheMealDbRemoteDataSource _remote;
  final RecipeLocalDataSource _local;
  final InternetConnectionService _net;

  @override
  FutureEither<DiscoveryResult> loadDiscovery({bool useLocation = true}) async {
    final meal = MealTimeContext.fromDateTime(DateTime.now());
    debugPrint(
      '[RecipeRepository] loadDiscovery slot=${meal.userLabel} category=${meal.categoryFilter}',
    );

    LocationContext? loc;
    if (useLocation) {
      final resolved = await LocationContextService.instance.resolve();
      loc = resolved;
      debugPrint(
        '[RecipeRepository] location area=${resolved.areaForMealDb} denied=${resolved.permissionDenied}',
      );
    }

    if (!await _net.hasConnection()) {
      return _offlineDiscoveryBundle(meal, loc);
    }

    final byCat = await _remote.filterByCategory(meal.categoryFilter);
    if (byCat.isLeft()) {
      debugPrint(
        '[RecipeRepository] category fetch → offline: ${byCat.getLeft().getOrElse(() => const ServerFailure('')).message}',
      );
      return _offlineDiscoveryBundle(meal, loc);
    }
    var list = byCat.getOrElse((_) => <RecipeSummary>[]);
    if (list.isEmpty) {
      return _offlineDiscoveryBundle(meal, loc);
    }

    if (loc != null &&
        (loc.areaForMealDb != null) &&
        loc.areaForMealDb!.isNotEmpty) {
      final areaR = await _remote.filterByArea(loc.areaForMealDb!);
      if (areaR.isRight()) {
        final areaList = areaR.getOrElse((_) => <RecipeSummary>[]);
        list = _mergeByPreference(list, areaList);
        debugPrint('[RecipeRepository] merged with area, count=${list.length}');
      }
    }
    list = _dedupe(list);
    await _storeDiscovery(list, meal, loc);
    return right(
      DiscoveryResult(
        items: list,
        meal: meal,
        location: loc,
        isOffline: false,
      ),
    );
  }

  List<RecipeSummary> _mergeByPreference(
    List<RecipeSummary> categoryList,
    List<RecipeSummary> areaList,
  ) {
    if (areaList.isEmpty) {
      return categoryList;
    }
    final areaIds = areaList.map((e) => e.id).toSet();
    final inBoth = categoryList.where((c) => areaIds.contains(c.id)).toList();
    if (inBoth.isNotEmpty) {
      return inBoth;
    }
    return _dedupe([...categoryList.take(6), ...areaList.take(6)]);
  }

  List<RecipeSummary> _dedupe(List<RecipeSummary> list) {
    final seen = <String>{};
    final out = <RecipeSummary>[];
    for (final r in list) {
      if (r.id.isEmpty) {
        continue;
      }
      if (seen.add(r.id)) {
        out.add(r);
      }
    }
    return out;
  }

  Future<void> _storeDiscovery(
    List<RecipeSummary> list,
    MealTimeContext meal,
    LocationContext? loc,
  ) async {
    final payload = jsonEncode({
      'summaries': list.map((e) => e.toMap()).toList(),
      'userLabel': meal.userLabel,
      'category': meal.categoryFilter,
      'area': loc?.areaForMealDb,
    });
    await _local.storeDiscoveryBundle(payload);
  }

  FutureEither<DiscoveryResult> _offlineDiscoveryBundle(
    MealTimeContext meal,
    LocationContext? loc,
  ) async {
    final raw = await _local.getDiscoveryBundle();
    if (raw == null) {
      final favs = await _local.allFavorites();
      if (favs.isEmpty) {
        return left(
          const NetworkFailure(
            'You are offline and there is no saved content yet. Connect once to load recipes.',
          ),
        );
      }
      return right(
        DiscoveryResult(
          items: favs
              .map(
                (d) => RecipeSummary(
                  id: d.id,
                  name: d.name,
                  thumbUrl: d.thumbUrl,
                  category: d.category,
                  area: d.area,
                ),
              )
              .toList(),
          meal: meal,
          location: loc,
          isOffline: true,
          offlineMessage: 'Offline — showing favorites only.',
        ),
      );
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['summaries'] as List<dynamic>)
        .map((e) => RecipeSummary.fromJsonMap(e as Map<String, dynamic>))
        .toList();
    return right(
      DiscoveryResult(
        items: list,
        meal: meal,
        location: loc,
        isOffline: true,
        offlineMessage: 'Offline — last saved picks.',
      ),
    );
  }

  @override
  FutureEither<List<RecipeSummary>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return right([]);
    }
    if (!await _net.hasConnection()) {
      return left(
        const NetworkFailure('Search needs internet. Try favorites while offline.'),
      );
    }
    return _remote.search(q);
  }

  @override
  FutureEither<RecipeDetail?> getRecipeById(
    String id, {
    bool allowStaleCache = true,
  }) async {
    if (id.isEmpty) {
      return right(null);
    }
    final online = await _net.hasConnection();
    if (!online) {
      if (!allowStaleCache) {
        return left(
          const NetworkFailure('Offline — recipe not in cache.'),
        );
      }
      final c = await _local.getCachedDetail(id);
      return c != null
          ? right(c)
          : left(const NetworkFailure('Offline — recipe not in cache.'));
    }
    final res = await _remote.lookupById(id);
    if (res.isLeft()) {
      if (allowStaleCache) {
        final c = await _local.getCachedDetail(id);
        if (c != null) {
          debugPrint('[RecipeRepository] using cached detail for $id');
          return right(c);
        }
      }
      return res;
    }
    final d = res.toNullable();
    if (d != null) {
      await _local.saveViewed(d);
    }
    return res;
  }

  @override
  Future<void> markViewed(RecipeDetail detail) => _local.saveViewed(detail);

  @override
  FutureEither<List<RecipeDetail>> favorites() async {
    return right(await _local.allFavorites());
  }

  @override
  Future<bool> isFavorite(String id) => _local.isFavorite(id);

  @override
  FutureEither<void> toggleFavorite(String id, {RecipeDetail? ifKnown}) async {
    final isF = await _local.isFavorite(id);
    if (isF) {
      await _local.removeFavorite(id);
      debugPrint('[RecipeRepository] un-favorited $id');
      return right(null);
    }
    var d = ifKnown;
    d ??= await _local.getCachedDetail(id);
    if (d == null) {
      if (await _net.hasConnection()) {
        final l = await _remote.lookupById(id);
        if (l.isLeft()) {
          return left(
            l.getLeft().getOrElse(() => const ServerFailure('Lookup failed')),
          );
        }
        final det = l.toNullable();
        if (det == null) {
          return left(
            const ServerFailure('Could not load recipe to favorite.'),
          );
        }
        await _local.setFavorite(det);
        return right(null);
      }
      return left(
        const NetworkFailure('Cannot favorite: open recipe online once, then try again offline.'),
      );
    }
    await _local.setFavorite(d);
    return right(null);
  }
}
