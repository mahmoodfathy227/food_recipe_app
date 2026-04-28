import 'package:food_app/src/imports/core_imports.dart';
import 'package:food_app/src/imports/packages_imports.dart';
import 'package:food_app/src/ui/recipes/bloc/recipe_detail_bloc.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return BlocBuilder<RecipeDetailBloc, RecipeDetailState>(
      builder: (context, state) {
        final d = state.detail;
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppTopBar(
            title: d?.name ?? 'Recipe',
            actions: [
              if (d != null)
                Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm.w),
                  child: IconButton(
                    tooltip: state.isFavorite ? 'Remove from saved' : 'Save offline',
                    onPressed: state.isLoading
                        ? null
                        : () {
                            debugPrint('[RecipeDetailPage] toggle favorite');
                            context
                                .read<RecipeDetailBloc>()
                                .add(const RecipeDetailFavoriteToggled());
                          },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, anim) {
                        return ScaleTransition(
                          scale: anim,
                          child: child,
                        );
                      },
                      child: Icon(
                        state.isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(state.isFavorite),
                        color: state.isFavorite ? cs.error : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null && d == null
                    ? _ErrorBody(
                        message: state.errorMessage!,
                        onRetry: () {
                        final bid = context.read<RecipeDetailBloc>();
                        bid.add(RecipeDetailLoadRequested(bid.recipeId));
                        debugPrint('[RecipeDetailPage] retry load');
                      },
                    )
                  : d == null
                      ? const Center(child: Text('Nothing to show'))
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.lg.w,
                                  AppSpacing.md.h,
                                  AppSpacing.lg.w,
                                  0,
                                ),
                                child: Hero(
                                  tag: 'meal-hero-${d.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.r),
                                    child: AppCachedImage(
                                      imageUrl: d.thumbUrl ?? '',
                                      height: 220.h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.lg.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (d.category != null)
                                      Text(
                                        '${d.category} · ${d.area ?? ''}'.trim(),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: cs.primary,
                                        ),
                                      ),
                                    SizedBox(height: AppSpacing.md.h),
                                    Text(
                                      'Instructions',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.sm.h),
                                    Text(
                                      d.instructions ?? '—',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        height: 1.4,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    if (d.ingredients.isNotEmpty) ...[
                                      SizedBox(height: AppSpacing.xl.h),
                                      Text(
                                        'Ingredients',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.sm.h),
                                      ...d.ingredients.map(
                                        (e) => Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4.h),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.fiber_manual_record,
                                                size: 8.sp,
                                                color: cs.primary,
                                              ),
                                              SizedBox(width: AppSpacing.sm.w),
                                              Expanded(
                                                child: Text(
                                                  e.measure != null
                                                      ? '${e.measure} ${e.ingredient}'
                                                      : e.ingredient,
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
