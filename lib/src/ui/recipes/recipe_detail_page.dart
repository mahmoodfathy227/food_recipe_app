import 'package:food_app/src/imports/core_imports.dart';
import 'package:food_app/src/imports/packages_imports.dart';
import 'package:food_app/src/ui/recipes/bloc/recipe_detail_bloc.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipeDetailBloc, RecipeDetailState>(
      builder: (context, state) {
        debugPrint(
          '[RecipeDetailPage] build isLoading=${state.isLoading} id=${state.detail?.id}',
        );
        final d = state.detail;
        final cs = context.theme.colorScheme;
        final tt = context.theme.textTheme;

        // ── Loading / error ──────────────────────────────────────
        if (state.isLoading && d == null) {
          return Scaffold(
            backgroundColor: cs.surface,
            body: Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          );
        }

        if (state.errorMessage != null && d == null) {
          return Scaffold(
            backgroundColor: cs.surface,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('😕', style: TextStyle(fontSize: 52.sp)),
                      SizedBox(height: 12.h),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: tt.bodyLarge,
                      ),
                      SizedBox(height: 20.h),
                      FilledButton(
                        onPressed: () {
                          final bloc = context.read<RecipeDetailBloc>();
                          bloc.add(RecipeDetailLoadRequested(bloc.recipeId));
                          debugPrint('[RecipeDetailPage] retry');
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (d == null) {
          return const Scaffold(
            body: Center(child: Text('Nothing to show')),
          );
        }

        // ── Full detail ──────────────────────────────────────────
        return Scaffold(
          backgroundColor: cs.surface,
          extendBodyBehindAppBar: true,
          body: CustomScrollView(
            slivers: [
              // ── Hero SliverAppBar ──────────────────────────
              SliverAppBar(
                expandedHeight: 300.h,
                pinned: true,
                backgroundColor: cs.surface,
                elevation: 0,
                leading: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: _FavoriteButton(
                      isFavorite: state.isFavorite,
                      isLoading: state.isLoading,
                      onTap: () {
                        context
                            .read<RecipeDetailBloc>()
                            .add(const RecipeDetailFavoriteToggled());
                        debugPrint(
                          '[RecipeDetailPage] toggle favorite → ${!state.isFavorite}',
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Recipe image
                      Hero(
                        tag: 'meal-hero-${d.id}',
                        child: AppCachedImage(
                          imageUrl: d.thumbUrl ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Bottom gradient → blends into surface
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.15),
                                cs.surface,
                              ],
                              stops: const [0.45, 0.72, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + area chip row
                      if (d.category != null)
                        Wrap(
                          spacing: 8.w,
                          children: [
                            if (d.category != null)
                              _Chip(label: d.category!, color: cs.primary),
                            if (d.area != null && d.area!.isNotEmpty)
                              _Chip(
                                label: '📍  ${d.area!}',
                                color: cs.secondary,
                              ),
                          ],
                        ),
                      SizedBox(height: 12.h),
                      // Recipe name
                      Text(
                        d.name,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Divider
                      Divider(color: cs.outlineVariant, thickness: 1),
                      SizedBox(height: 16.h),
                      // Instructions
                      if (d.instructions != null &&
                          d.instructions!.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 4.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Instructions',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          d.instructions!,
                          style: tt.bodyMedium?.copyWith(
                            height: 1.65,
                            color: cs.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                      // Ingredients
                      if (d.ingredients.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 4.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: cs.tertiary,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Ingredients',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ...d.ingredients.map(
                          (e) => _IngredientRow(ingredient: e),
                        ),
                      ],
                      SizedBox(height: 40.h),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onTap,
  });
  final bool isFavorite;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.red.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loader'),
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                  key: ValueKey(isFavorite),
                  color: Colors.white,
                  size: 18.sp,
                ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient});
  final dynamic ingredient;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final measure = ingredient.measure as String?;
    final name = ingredient.ingredient as String;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              measure != null && measure.isNotEmpty
                  ? '$measure $name'
                  : name,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
