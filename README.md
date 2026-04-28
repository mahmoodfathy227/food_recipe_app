# Bite & Time — Context-Aware Recipe Discovery

> Flutter recruitment assignment for **IVTEX Corporate Solutions** — Flutter Developer role.

A production-grade Flutter application that suggests recipes based on **where you are** and **what time it is**, built with an offline-first mindset and automated CI/CD delivery.

---

## Features at a Glance

| Area | What's built |
|---|---|
| **Smart Discovery** | Time-of-day categories (Breakfast / Lunch / Dinner) + device location → TheMealDB area filter |
| **Search** | Debounced full-text search (400 ms) against TheMealDB — zero unnecessary API calls |
| **Offline-First** | SQLite favorites + cached images + last-discovery bundle → app never shows a dead screen |
| **Notifications** | Daily meal nudges at **8:00 AM**, **2:00 PM**, **8:00 PM** — graceful permission denial handling |
| **UI/UX** | Skeleton loaders, Hero transitions (list ↔ detail), animated heart ♥ with ScaleTransition |
| **CI/CD** | GitHub Actions: analyze → test → release APK → auto-publish to GitHub Releases |

---

## Architecture

```
lib/src/
├── data/
│   ├── models/          # RecipeSummary, RecipeDetail, UserModel
│   ├── remote/          # TheMealDbRemoteDataSource (Dio)
│   ├── local/           # RecipeLocalDataSource (sqflite — favorites + cache)
│   └── repositories/    # RecipeRepository + RecipeRepositoryImpl
│
├── ui/
│   ├── home/            # Shell: Discover / Search / Saved tabs
│   ├── recipes/
│   │   ├── bloc/        # DiscoveryBloc · SearchBloc · FavoritesBloc · RecipeDetailBloc
│   │   └── recipe_detail_page.dart
│   ├── auth/
│   │   ├── bloc/        # AuthBloc · SessionBloc
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   └── onboarding/
│
├── services/
│   ├── meal_reminder_service.dart   # flutter_local_notifications — daily scheduled nudges
│   ├── location_context_service.dart # geolocator + geocoding → TheMealDB area
│   └── ...
│
├── utils/
│   ├── meal_time_context.dart       # Clock → Breakfast / Lunch / Dinner
│   └── debouncer.dart
│
└── routing/             # go_router — AppRouter + AppRoutes
```

### Key Decisions

- **State management — BLoC everywhere.** `DiscoveryBloc`, `SearchBloc`, `FavoritesBloc`, and `RecipeDetailBloc` own every async operation. Events are immutable and `Equatable`-backed, states carry the full render picture so widgets stay dumb.
- **Repository pattern.** `RecipeRepositoryImpl` is the single source of truth. It checks connectivity first, falls back to the local SQLite cache, and exposes `fpdart` `Either<Failure, T>` so the UI never crashes on network errors.
- **Contextual discovery.** `MealTimeContext` reads `DateTime.now()` to pick a category. `LocationContextService` maps the device country to a TheMealDB *area* string; if location is denied the app still works on time + cache alone.
- **Offline resilience.** `RecipeLocalDataSource` stores the last successful discovery bundle and all favorited full-detail payloads. `AppCachedImage` (cached_network_image) keeps thumbnails on disk. Losing connectivity shows a banner, not a blank screen.
- **No raw `setState` for business logic.** Only ephemeral UI state (e.g. `_index` in `HomePage`) uses `setState`.

---

## Running Locally

```bash
# 1. Get dependencies
flutter pub get

# 2. (Optional) override the API base URL — default is the free TheMealDB v1
cp .env.example .env

# 3. Run on a connected device / emulator
flutter run
```

> **Permissions asked at runtime:**  
> - **Location** — optional, refines results toward a regional cuisine  
> - **Notifications** — optional, enables daily meal reminders; tap the 🔔 bell on the Discover tab

---

## CI/CD Pipeline

File: [`.github/workflows/main.yml`](.github/workflows/main.yml)

**Triggered on every push to `main`** (and manually via `workflow_dispatch`).

```
Checkout → Java 17 → Flutter stable → pub get → create .env → analyze → test → build APK → upload artifact → create GitHub Release
```

| Step | Command |
|---|---|
| Static analysis | `flutter analyze` |
| Unit tests | `flutter test` |
| Release build | `flutter build apk --release` |
| Publish | `softprops/action-gh-release@v2` — tag `build-N`, attaches the APK |

The workflow uses the built-in `GITHUB_TOKEN` — no extra secrets needed.

### Trigger the pipeline manually

1. Go to **Actions → CI and release APK → Run workflow**
2. Select branch `main` → **Run workflow**
3. Once green, the APK appears in **Releases**

---

## Tech Stack

| Layer | Package |
|---|---|
| State | `flutter_bloc` + `equatable` |
| Navigation | `go_router` |
| HTTP | `dio` + `pretty_dio_logger` |
| Local DB | `sqflite` + `path_provider` |
| Image cache | `cached_network_image` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Location | `geolocator` + `geocoding` |
| UI helpers | `flutter_screenutil` · `skeletonizer` · `flutter_native_splash` |
| Functional | `fpdart` |
| Env | `flutter_dotenv` |

---

## Project Info

- **App name:** Bite & Time  
- **API:** [TheMealDB](https://www.themealdb.com/api.php) (free, no key required)  
- **Min SDK:** Android 21 / iOS 13  
- **Flutter channel:** stable
