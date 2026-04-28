import 'dart:async' show unawaited;

import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/imports/core_imports.dart';
import 'package:food_app/src/imports/packages_imports.dart';
import 'package:food_app/src/ui/recipes/bloc/discovery_bloc.dart';
import 'package:food_app/src/ui/recipes/bloc/favorites_bloc.dart';
import 'package:food_app/src/ui/recipes/bloc/search_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final _searchCtrl = TextEditingController();
  final _debounce = Debouncer(delay: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    // Dismiss the native splash as soon as the home shell is first rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[HomePage] removing native splash');
      FlutterNativeSplash.remove();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[HomePage] build product shell');
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                _DiscoverTab(
                  onEnableReminders: _maybeScheduleReminders,
                ),
                _SearchTab(
                  controller: _searchCtrl,
                  debouncer: _debounce,
                ),
                const _FavoritesTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68.h,
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 2) {
            context.read<FavoritesBloc>().add(const FavoritesLoadRequested());
            debugPrint('[HomePage] tab → favorites');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
        ],
      ),
    );
  }

  Future<void> _maybeScheduleReminders() async {
    if (!context.mounted) {
      return;
    }
    final repo = context.read<RecipeRepository>();
    await MealReminderService.requestAndSchedule(repo);
  }
}

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({
    required this.onEnableReminders,
  });

  final Future<void> Function() onEnableReminders;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, s) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppTopBar(
            showBack: false,
            title: 'Bite & Time',
            titleWidget: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bite & Time',
                  style: theme.appBarTheme.titleTextStyle
                          ?.copyWith(fontWeight: FontWeight.w700) ??
                      theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Recipes for your place and time',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Reminders',
                onPressed: onEnableReminders,
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                tooltip: 'Refresh + location',
                onPressed: () {
                  context.read<DiscoveryBloc>().add(
                        const DiscoveryLoadRequested(useLocation: true),
                      );
                  unawaited(_requestLocationIfNeeded());
                  debugPrint('[Discover] refresh');
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<DiscoveryBloc>().add(
                    const DiscoveryLoadRequested(useLocation: true),
                  );
              unawaited(_requestLocationIfNeeded());
            },
            child: _body(context, s, theme, onEnableReminders),
          ),
        );
      },
    );
  }
}

Future<void> _requestLocationIfNeeded() async {
  var st = await Permission.location.status;
  if (st.isDenied) {
    st = await Permission.location.request();
  }
  debugPrint('[Discover] location status=$st');
}

Widget _body(
  BuildContext context,
  DiscoveryState s,
  ThemeData theme,
  Future<void> Function() onReminders,
) {
  if (s.isLoading && s.data == null) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.md.h),
        itemCount: 6,
        itemBuilder: (_, i) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md.h),
            child: Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          );
        },
      ),
    );
  }
  if (s.errorMessage != null && s.data == null) {
    return _CenterMessage(
      icon: Icons.wifi_off_rounded,
      title: 'We could not load the feed',
      body: s.errorMessage!,
      onPrimary: 'Turn on meal reminders',
      onPrimaryAction: onReminders,
    );
  }
  final d = s.data;
  if (d == null) {
    return const _CenterMessage(
      icon: Icons.search,
      title: 'Nothing yet',
      body: 'Pull to refresh for recipe ideas',
    );
  }
  return CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg.w, AppSpacing.md.h, AppSpacing.lg.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.isOffline && d.offlineMessage != null) ...[
                Card(
                  color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(d.offlineMessage!),
                    subtitle: (d.location != null && d.location!.permissionDenied)
                        ? const Text('Location is off — using time of day only.')
                        : const Text('Favorites and cache stay available'),
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
              ] else
                const SizedBox.shrink(),
              Text(
                'It’s “${d.meal.userLabel}” o’clock',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                'Browsing: ${d.meal.categoryFilter} · '
                '${d.location?.areaForMealDb != null && d.location!.areaForMealDb!.isNotEmpty ? d.location!.areaForMealDb! : "Any region + your clock"}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.md.h),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (c, i) {
              if (i >= d.items.length) {
                return null;
              }
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                child: _RecipeListCard(
                  recipe: d.items[i],
                  onTap: () {
                    final id = d.items[i].id;
                    context.push('${AppRoutes.recipeBase}/$id');
                    debugPrint('[Discover] open $id');
                  },
                ),
              );
            },
            childCount: d.items.length,
          ),
        ),
      ),
    ],
  );
}

class _SearchTab extends StatelessWidget {
  const _SearchTab({required this.controller, required this.debouncer});
  final TextEditingController controller;
  final Debouncer debouncer;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppTopBar(
        showBack: false,
        title: 'Search',
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.sm.h),
            child: AppTextField(
              controller: controller,
              hint: 'Type a dish, ingredient, or style…',
              textInputAction: TextInputAction.search,
              onChanged: (q) {
                debouncer.run(() {
                  if (context.mounted) {
                    context.read<SearchBloc>().add(SearchQuerySubmitted(q));
                    debugPrint('[Search] debounced “$q”');
                  }
                });
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, s) {
                if (s.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (s.errorMessage != null) {
                  return _CenterMessage(
                    icon: Icons.wifi_off_outlined,
                    title: 'Search paused',
                    body: s.errorMessage!,
                  );
                }
                if (s.query.isEmpty) {
                  return const _CenterMessage(
                    icon: Icons.edit_note,
                    title: 'Find anything',
                    body: 'TheMealDB search — debounced so we only hit the network when you pause.',
                  );
                }
                if (s.results.isEmpty) {
                  return const _CenterMessage(
                    icon: Icons.search_off,
                    title: 'No matches',
                    body: 'Try a shorter keyword',
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.xs.h),
                  itemCount: s.results.length,
                  itemBuilder: (c, i) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                      child: _RecipeListCard(
                        recipe: s.results[i],
                        onTap: () {
                          final id = s.results[i].id;
                          context.push('${AppRoutes.recipeBase}/$id');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesTabContent extends StatelessWidget {
  const _FavoritesTabContent();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppTopBar(
        showBack: false,
        title: 'Saved for offline',
        actions: [
          IconButton(
            onPressed: () {
              context.read<FavoritesBloc>().add(const FavoritesLoadRequested());
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, s) {
          if (s.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.errorMessage != null) {
            return _CenterMessage(
              icon: Icons.error_outline,
              title: 'Could not read favorites',
              body: s.errorMessage!,
            );
          }
          if (s.items.isEmpty) {
            return const _CenterMessage(
              icon: Icons.favorite_border,
              title: 'No saved recipes',
              body: 'Tap the heart on a recipe — it is stored in SQLite and works on a plane.',
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            itemCount: s.items.length,
            itemBuilder: (c, i) {
              final d = s.items[i];
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                child: _RecipeListCard(
                  recipe: RecipeSummary(
                    id: d.id,
                    name: d.name,
                    thumbUrl: d.thumbUrl,
                    category: d.category,
                    area: d.area,
                  ),
                  onTap: () {
                    context.push('${AppRoutes.recipeBase}/${d.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecipeListCard extends StatelessWidget {
  const _RecipeListCard({required this.recipe, required this.onTap});
  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'meal-hero-${recipe.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  bottomLeft: Radius.circular(20.r),
                ),
                child: AppCachedImage(
                  imageUrl: recipe.thumbUrl ?? '',
                  width: 100.w,
                  height: 100.h,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      [recipe.category, recipe.area]
                          .whereType<String>()
                          .where((e) => e.isNotEmpty)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 4.w),
          ],
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.onPrimary,
    this.onPrimaryAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? onPrimary;
  final Future<void> Function()? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        padding: EdgeInsets.all(32.w),
        children: [
          Icon(icon, size: 48.sp, color: context.theme.colorScheme.primary),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.theme.textTheme.bodyMedium,
          ),
          if (onPrimary != null && onPrimaryAction != null) ...[
            SizedBox(height: 24.h),
            FilledButton(
              onPressed: () => onPrimaryAction!(),
              child: Text(onPrimary!),
            ),
          ],
        ],
      ),
    );
  }
}

