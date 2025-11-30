import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_movies';

  Future<List<MovieAvailability>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(favoritesJson);
    return decoded.map((e) => MovieAvailability.fromJson(e)).toList();
  }

  Future<void> toggleFavorite(MovieAvailability movie) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    final index = favorites.indexWhere((m) => m.movie.title == movie.movie.title);
    
    if (index >= 0) {
      // Remove
      favorites.removeAt(index);
    } else {
      // Add
      favorites.add(movie);
    }
    
    await prefs.setString(_favoritesKey, json.encode(favorites.map((e) => e.toJson()).toList()));
  }

  Future<void> updateFavorite(MovieAvailability movie) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    final index = favorites.indexWhere((m) => m.movie.title == movie.movie.title);
    
    if (index >= 0) {
      favorites[index] = movie;
      await prefs.setString(_favoritesKey, json.encode(favorites.map((e) => e.toJson()).toList()));
    }
  }

  Future<bool> isFavorite(String movieTitle) async {
    final favorites = await getFavorites();
    return favorites.any((m) => m.movie.title == movieTitle);
  }
}
