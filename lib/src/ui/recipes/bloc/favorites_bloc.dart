import 'package:flutter/foundation.dart';
import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/imports/packages_imports.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

class FavoritesLoadRequested extends FavoritesEvent {
  const FavoritesLoadRequested();
}

class FavoritesState extends Equatable {
  final bool isLoading;
  final List<RecipeDetail> items;
  final String? errorMessage;
  const FavoritesState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
  });
  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final RecipeRepository _repo;

  FavoritesBloc({required RecipeRepository recipeRepository})
      : _repo = recipeRepository,
        super(const FavoritesState()) {
    on<FavoritesLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    FavoritesLoadRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesState(isLoading: true));
    debugPrint('[FavoritesBloc] load');
    final r = await _repo.favorites();
    r.fold(
      (f) {
        emit(FavoritesState(isLoading: false, errorMessage: f.message));
      },
      (list) {
        emit(FavoritesState(isLoading: false, items: list));
      },
    );
  }
}
