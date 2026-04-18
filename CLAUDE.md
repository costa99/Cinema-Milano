# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                  # Install dependencies
flutter analyze                  # Lint / static analysis
flutter test                     # Run tests
flutter run                      # Debug run (prompts for device)
flutter build apk                # Build Android APK
```

### API URL configuration

The backend URL defaults to `https://homescrapy.xyz`. Override via Dart environment variable for local dev:

```bash
# Emulator (Android AVD)
flutter run --dart-define=API_URL=http://10.0.2.2:8001

# Physical device on local network
flutter run --dart-define=API_URL=http://192.168.1.X:8001
```

## Architecture

Flutter app for browsing Milan cinema showtimes, backed by a custom scraper API at `homescrapy.xyz`.

### Layer overview

```
lib/
├── main.dart                        # Entry point; theme wiring + Workmanager init
├── models/movie.dart                # All data models (Movie, ShowTime, CinemaAvailability, MovieAvailability)
├── services/
│   ├── api_service.dart             # HTTP client — all network calls
│   ├── theme_service.dart           # ChangeNotifier theme state (persisted via SharedPreferences)
│   ├── favorites_service.dart       # Favorites list (SharedPreferences, JSON)
│   └── background_service.dart      # Workmanager task: checks favorites for new showtimes every 2h
└── screens/
    ├── movie_list_screen.dart        # Main screen: tabbed Current / Coming Soon grid
    ├── cinema_availability_screen.dart  # Movie detail + showtime list per cinema/date
    ├── favorites_screen.dart         # 2-column grid of saved favorites
    └── settings_screen.dart          # Theme picker
```

### Data flow

`ApiService` fetches `MovieAvailability` objects from the REST backend. The main screen uses `FutureBuilder` to display them; `FavoritesService` persists a subset to SharedPreferences. `BackgroundService` re-fetches favorite movies in a Workmanager isolate, diffs showtimes, and fires local notifications for anything new.

### State management

No external state management library. UI state lives in `StatefulWidget`+`setState`. Theme is a `ChangeNotifier` consumed via `ListenableBuilder`. Background work uses Workmanager's callback dispatcher (top-level function required by the plugin).

### Themes

Four themes defined in `main.dart`: System Default, Light, Dark, and **Neon** (pink/cyan/yellow Material3 palette). Selected theme is persisted by `ThemeController` and applied at the root `MaterialApp`.

### API endpoints

| Endpoint | Returns |
|---|---|
| `GET /movies` | All `MovieAvailability` |
| `GET /movies/current` | Currently showing |
| `GET /movies/comingsoon` | Coming soon |
| `GET /movies/details` | Full detail for a single movie |

### Android notes

- `minSdkVersion 21`, core library desugaring enabled (needed for `java.time` APIs used by date formatting)
- Permissions: `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`
- Calendar integration via `add_2_calendar`; long-press a showtime chip to add it to the device calendar
