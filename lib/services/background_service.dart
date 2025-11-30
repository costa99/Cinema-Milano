import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'favorites_service.dart';
import '../models/movie.dart';

const String taskName = 'check_schedules';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      await _checkSchedules();
    }
    return Future.value(true);
  });
}

Future<void> _checkSchedules() async {
  final favoritesService = FavoritesService();
  final apiService = ApiService();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  try {
    final favorites = await favoritesService.getFavorites();
    if (favorites.isEmpty) return;

    // Fetch latest movies. 
    // We assume getMovies() returns the general list of movies with upcoming showtimes.
    // If specific date filtering is needed, we might need to iterate dates, 
    // but usually the main endpoint returns relevant current/upcoming info.
    final latestMovies = await apiService.getMovies(); 
    
    for (var fav in favorites) {
      try {
        final latestMovie = latestMovies.firstWhere(
          (m) => m.movie.title == fav.movie.title,
        );
        
        bool hasNewShowtimes = false;
        List<String> newTimes = [];

        for (var latestCinema in latestMovie.cinemas) {
           var favCinema = fav.cinemas.firstWhere(
             (c) => c.cinemaName == latestCinema.cinemaName && c.date == latestCinema.date,
             orElse: () => CinemaAvailability(cinemaName: '', date: '', showtimes: []),
           );
           
           if (favCinema.cinemaName.isEmpty) {
             // New cinema or date
             if (latestCinema.showtimes.isNotEmpty) {
               hasNewShowtimes = true;
               newTimes.add('${latestCinema.cinemaName} (${latestCinema.date})');
             }
           } else {
             // Compare showtimes
             final favTimes = favCinema.showtimes.map((s) => s.time).toSet();
             for (var showtime in latestCinema.showtimes) {
               if (!favTimes.contains(showtime.time)) {
                 hasNewShowtimes = true;
                 newTimes.add('${latestCinema.cinemaName} ${showtime.time}');
               }
             }
           }
        }

        if (hasNewShowtimes) {
           const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'cinema_scraper_channel',
            'Cinema Scraper Notifications',
            channelDescription: 'Notifications for new movie showtimes',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          
          await flutterLocalNotificationsPlugin.show(
            fav.movie.title.hashCode,
            'New Showtimes for ${fav.movie.title}',
            'Found new times: ${newTimes.take(3).join(", ")}${newTimes.length > 3 ? "..." : ""}',
            platformChannelSpecifics,
          );

          await favoritesService.updateFavorite(latestMovie);
        }

      } catch (e) {
        // Movie not found in latest list
        continue;
      }
    }

  } catch (e) {
    print('Error in background task: $e');
  }
}
