# Cinema‑Milano Frontend

A **Flutter** mobile application that displays movie listings and showtimes scraped from Italian cinema websites.

---

## ✨ Features
- **Explore movies**: Browse currently showing films with rich posters, titles, and concise summaries.
- **Showtime navigation**: View detailed showtimes for each cinema, complete with dates and direct booking links.
- **Calendar integration**: Quickly add a showtime to your personal calendar via a long‑press on the time chip.
- **Favorites management**: Mark and organize your preferred movies for easy access.
- **Dynamic theming**: Switch between light, dark, or system‑aligned themes for a personalized UI.
- **Offline support**: Cached movie data ensures fast loading and offline accessibility.

---

## 🚀 Getting Started
### Prerequisites
- **Flutter SDK** (≥3.19)
- **Android Studio** or another IDE with Flutter support.
- The **backend** must be running (see the backend README for details).

### Installation
```bash
# Clone the repository (if not already done)
git clone https://github.com/costa99/cinema‑scraper‑frontend.git
cd cinema‑scraper‑frontend

# Get Flutter dependencies
flutter pub get
```

### Running the app
```bash
# Connect a device or start an emulator
flutter devices

# Run in debug mode
flutter run
```
The app will attempt to connect to the backend at `http://10.0.2.2:8000` (Android emulator) or `http://localhost:8000` (iOS simulator). Adjust the `BASE_URL` in `lib/config.dart` if needed.

---

## 📦 Project Structure
```
lib/
├─ components/          # Re‑usable UI widgets (movie cards, chips, etc.)
├─ screens/             # Page‑level widgets (MovieListScreen, SettingsScreen…)
├─ models/              # Data classes mirroring the backend API
├─ services/            # API client and caching logic
├─ themes/              # Theme definitions and ThemeController
├─ config.dart          # Global configuration (backend URL, etc.)
└─ main.dart            # App entry point
```

---

## 🛠️ Development Tips
- **Hot reload** works as usual – press `r` in the console.
- Run `flutter test` to execute the unit and widget tests.
- Use `flutter analyze` to lint the code.
- To add a new screen, create it under `screens/` and register the route in `main.dart`.

---

## 📄 License
This project is licensed under the MIT License – see the `LICENSE` file for details.

---

## 🙏 Contributing
Contributions are welcome! Please open an issue or submit a pull request. Follow the standard Flutter contribution guidelines and ensure all tests pass.
