import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiService {
  // Production domain
  static const String _productionDomain = 'homescrapy.xyz';
  static const String _localDomain = 'http://localhost:8001';

  // Get API URL from Dart defines or use local as default for testing
  // Usage:
  //   Production: flutter run --dart-define=API_URL=https://homescrapy.xyz
  //   Android Emulator: flutter run --dart-define=API_URL=http://10.0.2.2:8001
  //   Physical Device: flutter run --dart-define=API_URL=http://192.168.1.x:8001
  String get baseUrl {
    const apiUrl = String.fromEnvironment('API_URL', defaultValue: _localDomain);
    // If it's just the domain (no protocol), add https://
    if (!apiUrl.startsWith('http://') && !apiUrl.startsWith('https://')) {
      return 'https://$apiUrl';
    }
    return apiUrl;
  }

  Future<List<MovieAvailability>> getMovies({String? date}) async {
    try {
      var uri = Uri.parse('$baseUrl/movies');
      if (date != null) {
        uri = uri.replace(queryParameters: {'date': date});
      }
      print('Requesting: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final movies = data.map((json) => MovieAvailability.fromJson(json)).toList();
        print('Fetched ${movies.length} movies: ${movies.map((m) => m.movie.title).join(', ')}');
        return movies;
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<List<MovieAvailability>> getCurrentMovies() async {
    try {
      final uri = Uri.parse('$baseUrl/movies/current');
      print('Requesting: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final movies = data.map((json) => MovieAvailability.fromJson(json)).toList();
        print('Fetched ${movies.length} current movies: ${movies.map((m) => m.movie.title).join(', ')}');
        return movies;
      } else {
        throw Exception('Failed to load current movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<List<MovieAvailability>> getComingSoonMovies() async {
    try {
      final uri = Uri.parse('$baseUrl/movies/comingsoon');
      print('Requesting: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final movies = data.map((json) => MovieAvailability.fromJson(json)).toList();
        print('Fetched ${movies.length} coming soon movies: ${movies.map((m) => m.movie.title).join(', ')}');
        return movies;
      } else {
        throw Exception('Failed to load coming soon movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<Map<String, dynamic>> getMovieDetails(String url, String cinemaName) async {
    try {
      final queryParameters = {
        'url': url,
        'cinema_name': cinemaName,
      };
      final uri = Uri.parse('$baseUrl/movies/details').replace(queryParameters: queryParameters);
      print('Requesting: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load movie details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
