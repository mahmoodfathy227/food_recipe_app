import 'package:flutter/foundation.dart';
import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/imports/packages_imports.dart';
import 'package:food_app/src/utils/failure.dart';

abstract class RecipeDetailEvent extends Equatable {
  const RecipeDetailEvent();
  @override
  List<Object?> get props => [];
}

class RecipeDetailLoadRequested extends RecipeDetailEvent {
  final String recipeId;
  const RecipeDetailLoadRequested(this.recipeId);
  @override
  List<Object?> get props => [recipeId];
}

class RecipeDetailFavoriteToggled extends RecipeDetailEvent {
  const RecipeDetailFavoriteToggled();
}

// ---

class RecipeDetailState extends Equatable {
  final bool isLoading;
  final RecipeDetail? detail;
  final bool isFavorite;
  final String? errorMessage;
  const RecipeDetailState({
    this.isLoading = false,
    this.detail,
    this.isFavorite = false,
    this.errorMessage,
  });
  @override
  List<Object?> get props => [isLoading, detail, isFavorite, errorMessage];
}

// ---

class RecipeDetailBloc extends Bloc<RecipeDetailEvent, RecipeDetailState> {
  final RecipeRepository _repo;
  final String recipeId;

  RecipeDetailBloc({
    required RecipeRepository recipeRepository,
    required this.recipeId,
  })  : _repo = recipeRepository,
        super(const RecipeDetailState(isLoading: true)) {
    on<RecipeDetailLoadRequested>(_onLoad);
    on<RecipeDetailFavoriteToggled>(_onToggle);
    add(RecipeDetailLoadRequested(recipeId));
  }

  Future<void> _onLoad(
    RecipeDetailLoadRequested event,
    Emitter<RecipeDetailState> emit,
  ) async {
    emit(const RecipeDetailState(isLoading: true));
    debugPrint('[RecipeDetailBloc] load id=${event.recipeId}');
    final fav = await _repo.isFavorite(event.recipeId);
    final r = await _repo.getRecipeById(event.recipeId);
    r.fold(
      (f) {
        emit(
          RecipeDetailState(
            isLoading: false,
            errorMessage: f.message,
            isFavorite: fav,
          ),
        );
      },
      (d) {
        emit(
          RecipeDetailState(
            isLoading: false,
            detail: d,
            isFavorite: fav,
            errorMessage: d == null ? 'Recipe not found' : null,
          ),
        );
      },
    );
  }

  Future<void> _onToggle(
    RecipeDetailFavoriteToggled event,
    Emitter<RecipeDetailState> emit,
  ) async {
    final d = state.detail;
    final r = await _repo.toggleFavorite(recipeId, ifKnown: d);
    if (r.isLeft()) {
      emit(
        RecipeDetailState(
          isLoading: false,
          detail: d,
          isFavorite: state.isFavorite,
          errorMessage:
              r.getLeft().getOrElse(() => const ServerFailure('Error')).message,
        ),
      );
      return;
    }
    final fav = await _repo.isFavorite(recipeId);
    emit(
      RecipeDetailState(
        isLoading: false,
        detail: d,
        isFavorite: fav,
        errorMessage: null,
      ),
    );
    debugPrint('[RecipeDetailBloc] favorite → $fav');
  }
}
