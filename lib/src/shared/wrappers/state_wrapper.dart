import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../imports/imports.dart';
import '../../ui/recipes/bloc/discovery_bloc.dart';
import '../../ui/recipes/bloc/favorites_bloc.dart';
import '../../ui/recipes/bloc/search_bloc.dart';

/// A wrapper to initialize the chosen State Management library.
class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<RecipeRepository>(
      create: (_) {
        debugPrint('[StateWrapper] RecipeRepository init');
        return RecipeRepositoryImpl();
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (c) {
              final repo = c.read<RecipeRepository>();
              debugPrint('[StateWrapper] DiscoveryBloc init without auth gate');
              return DiscoveryBloc(recipeRepository: repo)
                ..add(const DiscoveryLoadRequested());
            },
          ),
          BlocProvider(
            create: (c) => SearchBloc(recipeRepository: c.read<RecipeRepository>()),
          ),
          BlocProvider(
            create: (c) => FavoritesBloc(recipeRepository: c.read<RecipeRepository>()),
          ),
        ],
        child: child,
      ),
    );
  }
}
