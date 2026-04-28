import 'dart:async' show unawaited;

import 'package:food_app/src/data/models/recipe_model.dart';
import 'package:food_app/src/data/repositories/recipe_repository.dart';
import 'package:food_app/src/imports/core_imports.dart';
import 'package:food_app/src/imports/packages_imports.dart';
import 'package:food_app/src/ui/recipes/bloc/discovery_bloc.dart';
import 'package:food_app/src/ui/recipes/bloc/favorites_bloc.dart';
import 'package:food_app/src/ui/recipes/bloc/search_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell
// ─────────────────────────────────────────────────────────────────────────────

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
    debugPrint('[HomePage] build product shell index=$_index');
    final cs = context.theme.colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: IndexedStack(
        index: _index,
        children: [
          _DiscoverTab(onEnableReminders: _maybeScheduleReminders),
          _SearchTab(controller: _searchCtrl, debouncer: _debounce),
          const _FavoritesTab(),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        index: _index,
        onChanged: (i) {
          setState(() => _index = i);
          if (i == 2) {
            context.read<FavoritesBloc>().add(const FavoritesLoadRequested());
            debugPrint('[HomePage] tab → favorites');
          }
        },
      ),
    );
  }

  Future<void> _maybeScheduleReminders() async {
    if (!context.mounted) return;
    final repo = context.read<RecipeRepository>();
    await MealReminderService.requestAndSchedule(repo);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        height: 66.h,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: index,
        onDestinationSelected: onChanged,
        indicatorColor: cs.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Discover Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({required this.onEnableReminders});
  final Future<void> Function() onEnableReminders;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, s) {
        debugPrint(
          '[DiscoverTab] build isLoading=${s.isLoading} hasData=${s.data != null}',
        );
        return _DiscoverScaffold(
          state: s,
          onEnableReminders: onEnableReminders,
        );
      },
    );
  }
}

class _DiscoverScaffold extends StatelessWidget {
  const _DiscoverScaffold({
    required this.state,
    required this.onEnableReminders,
  });
  final DiscoveryState state;
  final Future<void> Function() onEnableReminders;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final d = state.data;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── App bar ──────────────────────────────────────────────
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: cs.surface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              if (d != null)
                Text(
                  '${d.meal.categoryFilter} · '
                  '${(d.location?.areaForMealDb?.isNotEmpty ?? false) ? d.location!.areaForMealDb! : "Any cuisine"}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Reminders',
              onPressed: onEnableReminders,
              icon: Icon(
                Icons.notifications_outlined,
                color: cs.onSurface,
              ),
            ),
            IconButton(
              tooltip: 'Refresh + location',
              onPressed: () {
                context.read<DiscoveryBloc>().add(
                      const DiscoveryLoadRequested(useLocation: true),
                    );
                unawaited(_requestLocation());
                debugPrint('[DiscoverTab] refresh tapped');
              },
              icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            ),
          ],
        ),

        // ── Offline banner ────────────────────────────────────────
        if (d != null && d.isOffline && d.offlineMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: _OfflineBanner(message: d.offlineMessage!),
            ),
          ),

        // ── Pull-to-refresh hint (always-scrollable) ─────────────
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            context.read<DiscoveryBloc>().add(
                  const DiscoveryLoadRequested(useLocation: true),
                );
            unawaited(_requestLocation());
          },
        ),

        // ── Content ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildBody(context, state, onEnableReminders),
        ),

        // ── Developer card — always visible ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
            child: const _DeveloperCard(),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return '🌅  Good Morning!';
    if (h >= 12 && h < 17) return '☀️  Good Afternoon!';
    if (h >= 17 && h < 21) return '🌆  Good Evening!';
    return '🌙  Good Night!';
  }
}

Widget _buildBody(
  BuildContext context,
  DiscoveryState s,
  Future<void> Function() onReminders,
) {
  final cs = context.theme.colorScheme;
  final tt = context.theme.textTheme;

  // Loading
  if (s.isLoading && s.data == null) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Skeletonizer(
        enabled: true,
        child: Column(
          children: [
            // Fake featured card
            Container(
              height: 220.h,
              width: double.infinity,
              margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            // Fake list cards
            ...List.generate(
              4,
              (_) => Container(
                height: 88.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error with no data
  if (s.errorMessage != null && s.data == null) {
    return _EmptyState(
      emoji: '📡',
      title: 'Could not load recipes',
      body: s.errorMessage!,
      actionLabel: 'Enable meal reminders',
      onAction: onReminders,
    );
  }

  final d = s.data;
  if (d == null || d.items.isEmpty) {
    return const _EmptyState(
      emoji: '🍽️',
      title: 'Nothing yet',
      body: 'Pull down to fetch recipe ideas',
    );
  }

  final featured = d.items.first;
  final rest = d.items.skip(1).toList();

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        // ── Featured card ────────────────────────────────
        _FeaturedCard(
          recipe: featured,
          mealLabel: d.meal.userLabel,
          onTap: () {
            context.push('${AppRoutes.recipeBase}/${featured.id}');
            debugPrint('[Discover] open featured ${featured.id}');
          },
        ),
        if (rest.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'More ideas',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          ...rest.map(
            (r) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _RecipeCard(
                recipe: r,
                onTap: () {
                  context.push('${AppRoutes.recipeBase}/${r.id}');
                  debugPrint('[Discover] open ${r.id}');
                },
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Future<void> _requestLocation() async {
  var st = await Permission.location.status;
  if (st.isDenied) st = await Permission.location.request();
  debugPrint('[Discover] location status=$st');
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Tab
// ─────────────────────────────────────────────────────────────────────────────

class _SearchTab extends StatelessWidget {
  const _SearchTab({required this.controller, required this.debouncer});
  final TextEditingController controller;
  final Debouncer debouncer;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Padding(
              padding:
                  EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔍  Search Recipes',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(fontSize: 15.sp),
                      decoration: InputDecoration(
                        hintText: 'Pasta, chicken, tacos…',
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 15.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onChanged: (q) {
                        debouncer.run(() {
                          if (context.mounted) {
                            context
                                .read<SearchBloc>()
                                .add(SearchQuerySubmitted(q));
                            debugPrint('[Search] debounced "$q"');
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, s) {
                  if (s.isLoading) {
                    return _SearchSkeleton(cs: cs);
                  }
                  if (s.errorMessage != null) {
                    return _EmptyState(
                      emoji: '📡',
                      title: 'Search paused',
                      body: s.errorMessage!,
                    );
                  }
                  if (s.query.isEmpty) {
                    return const _EmptyState(
                      emoji: '🍴',
                      title: 'Find any recipe',
                      body:
                          'Results from TheMealDB — debounced so we only fetch when you pause.',
                    );
                  }
                  if (s.results.isEmpty) {
                    return const _EmptyState(
                      emoji: '🤔',
                      title: 'No matches',
                      body: 'Try a shorter keyword',
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    itemCount: s.results.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _RecipeCard(
                        recipe: s.results[i],
                        onTap: () {
                          final id = s.results[i].id;
                          context.push('${AppRoutes.recipeBase}/$id');
                          debugPrint('[Search] open $id');
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 88.h,
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Favorites Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, s) {
            debugPrint(
              '[FavoritesTab] build isLoading=${s.isLoading} items=${s.items.length}',
            );
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: cs.surface,
                  elevation: 0,
                  title: Text(
                    '🔖  Saved Recipes',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        context
                            .read<FavoritesBloc>()
                            .add(const FavoritesLoadRequested());
                        debugPrint('[FavoritesTab] refresh');
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                if (s.isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    ),
                  )
                else if (s.errorMessage != null)
                  SliverFillRemaining(
                    child: _EmptyState(
                      emoji: '⚠️',
                      title: 'Could not load saved recipes',
                      body: s.errorMessage!,
                    ),
                  )
                else if (s.items.isEmpty)
                  const SliverFillRemaining(
                    child: _EmptyState(
                      emoji: '❤️',
                      title: 'No saved recipes yet',
                      body:
                          'Tap the heart on any recipe — it saves to SQLite and works offline.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final item = s.items[i];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _RecipeCard(
                              recipe: RecipeSummary(
                                id: item.id,
                                name: item.name,
                                thumbUrl: item.thumbUrl,
                                category: item.category,
                                area: item.area,
                              ),
                              onTap: () {
                                context.push(
                                  '${AppRoutes.recipeBase}/${item.id}',
                                );
                                debugPrint('[Favorites] open ${item.id}');
                              },
                            ),
                          );
                        },
                        childCount: s.items.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Card (hero recipe at top of discover)
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.recipe,
    required this.mealLabel,
    required this.onTap,
  });
  final RecipeSummary recipe;
  final String mealLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    debugPrint('[_FeaturedCard] build ${recipe.id}');
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'meal-hero-${recipe.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: SizedBox(
            height: 220.h,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                AppCachedImage(
                  imageUrl: recipe.thumbUrl ?? '',
                  fit: BoxFit.cover,
                ),
                // Gradient overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.3, 0.55, 1.0],
                    ),
                  ),
                ),
                // Meal label chip
                Positioned(
                  top: 14.h,
                  left: 14.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '✨  $mealLabel pick',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Title + subtitle
                Positioned(
                  left: 16.w,
                  right: 16.w,
                  bottom: 16.h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        [recipe.category, recipe.area]
                            .whereType<String>()
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regular Recipe Card (horizontal – image left, text right)
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.onTap});
  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              // Thumbnail
              Hero(
                tag: 'meal-hero-${recipe.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    bottomLeft: Radius.circular(18.r),
                  ),
                  child: AppCachedImage(
                    imageUrl: recipe.thumbUrl ?? '',
                    width: 90.w,
                    height: 88.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Text
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        [recipe.category, recipe.area]
                            .whereType<String>()
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline Banner
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: cs.tertiary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18.sp,
            color: cs.tertiary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String body;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 56.sp)),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24.h),
              FilledButton(
                onPressed: () => onAction!(),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Developer Card
// ─────────────────────────────────────────────────────────────────────────────

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();

  @override
  Widget build(BuildContext context) {
    debugPrint('[_DeveloperCard] build');
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.10),
            cs.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          // Avatar circle
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                'MF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Coded by Mahmood Fathy',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          // Contact row – email
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'mahmoodfathy246@gmail.com',
            color: cs.primary,
          ),
          SizedBox(height: 6.h),
          // Contact row – phone
          _ContactRow(
            icon: Icons.phone_outlined,
            label: '+20 106 629 3631',
            color: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
