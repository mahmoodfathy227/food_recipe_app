import 'package:flutter/foundation.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/imports/packages_imports.dart';

// ---

abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();
  @override
  List<Object?> get props => [];
}

class DiscoveryLoadRequested extends DiscoveryEvent {
  final bool useLocation;
  const DiscoveryLoadRequested({this.useLocation = true});
  @override
  List<Object?> get props => [useLocation];
}

// ---

class DiscoveryState extends Equatable {
  final bool isLoading;
  final DiscoveryResult? data;
  final String? errorMessage;
  const DiscoveryState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
  });
  @override
  List<Object?> get props => [isLoading, data, errorMessage];
}

// ---

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final RecipeRepository _repo;

  DiscoveryBloc({required RecipeRepository recipeRepository})
      : _repo = recipeRepository,
        super(const DiscoveryState()) {
    on<DiscoveryLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    DiscoveryLoadRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(const DiscoveryState(isLoading: true));
    debugPrint('[DiscoveryBloc] load useLocation=${event.useLocation}');
    final r = await _repo.loadDiscovery(useLocation: event.useLocation);
    r.fold(
      (f) {
        emit(DiscoveryState(isLoading: false, errorMessage: f.message));
      },
      (data) {
        emit(DiscoveryState(isLoading: false, data: data));
      },
    );
  }
}
