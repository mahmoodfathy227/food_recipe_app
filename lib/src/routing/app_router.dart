import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/routing/global_navigator.dart';
import 'package:food_app/src/routing/app_routes.dart';
import 'package:food_app/src/ui/home/home_page.dart';
import 'package:food_app/src/ui/recipes/bloc/recipe_detail_bloc.dart';
import 'package:food_app/src/ui/recipes/recipe_detail_page.dart';


final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) {
        debugPrint('[app_router] open home discovery');
        return const HomePage();
      },
    ),
    GoRoute(
      path: '${AppRoutes.recipeBase}/:id',
      name: 'recipeDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        debugPrint('[app_router] open recipe $id');
        return BlocProvider(
          create: (c) {
            return RecipeDetailBloc(
              recipeRepository: c.read<RecipeRepository>(),
              recipeId: id,
            );
          },
          child: const RecipeDetailPage(),
        );
      },
    ),
  ],
);
