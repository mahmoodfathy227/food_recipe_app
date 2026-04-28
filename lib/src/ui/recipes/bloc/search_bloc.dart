import 'package:flutter/foundation.dart';
import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/imports/packages_imports.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQuerySubmitted extends SearchEvent {
  final String query;
  const SearchQuerySubmitted(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

// ---

class SearchState extends Equatable {
  final String query;
  final bool isLoading;
  final List<RecipeSummary> results;
  final String? errorMessage;
  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.errorMessage,
  });
  @override
  List<Object?> get props => [query, isLoading, results, errorMessage];
}

// ---

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final RecipeRepository _repo;

  SearchBloc({required RecipeRepository recipeRepository})
      : _repo = recipeRepository,
        super(const SearchState()) {
    on<SearchQuerySubmitted>(_onQuery);
    on<SearchCleared>(_onCleared);
  }

  Future<void> _onQuery(
    SearchQuerySubmitted event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const SearchState());
      return;
    }
    emit(
      SearchState(
        query: event.query,
        isLoading: true,
        errorMessage: null,
        results: const [],
      ),
    );
    debugPrint('[SearchBloc] query="${event.query}"');
    final r = await _repo.search(event.query);
    r.fold(
      (f) {
        emit(
          SearchState(
            query: event.query,
            isLoading: false,
            errorMessage: f.message,
          ),
        );
      },
      (list) {
        emit(
          SearchState(
            query: event.query,
            isLoading: false,
            results: list,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }
}
