import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/services/location_context_service.dart';
import 'package:food_app/src/utils/meal_time_context.dart';
import 'package:food_app/src/utils/typedefs.dart';

class DiscoveryResult {
  final List<RecipeSummary> items;
  final MealTimeContext meal;
  final LocationContext? location;
  final bool isOffline;
  final String? offlineMessage;

  const DiscoveryResult({
    required this.items,
    required this.meal,
    this.location,
    this.isOffline = false,
    this.offlineMessage,
  });
}

abstract class RecipeRepository {
  /// Context-aware list (time + optional location merge). Falls back to SQLite / last bundle.
  FutureEither<DiscoveryResult> loadDiscovery({bool useLocation = true});

  /// Debounce handled in Bloc; repository only loads.
  FutureEither<List<RecipeSummary>> search(String query);

  FutureEither<RecipeDetail?> getRecipeById(
    String id, {
    bool allowStaleCache = true,
  });

  /// Marks viewed for offline access.
  Future<void> markViewed(RecipeDetail detail);

  FutureEither<List<RecipeDetail>> favorites();

  Future<bool> isFavorite(String id);

  FutureEither<void> toggleFavorite(String id, {RecipeDetail? ifKnown});
}
