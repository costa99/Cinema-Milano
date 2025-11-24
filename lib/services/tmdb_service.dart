import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secrets.dart';

class TMDBService {
  final String _apiKey = tmdbApiKey;
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  Future<Map<String, dynamic>?> searchMovie(String query) async {
    if (_apiKey == 'YOUR_TMDB_API_KEY') {
      print('TMDB API Key not set.');
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl/search/movie').replace(queryParameters: {
        'api_key': _apiKey,
        'query': query,
        'language': 'it-IT', // Search in Italian as the app seems to be for Italian cinemas
        'include_adult': 'false',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          return results.first as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error searching TMDB: $e');
    }
    return null;
  }

  String? getPosterUrl(String? posterPath) {
    if (posterPath == null) return null;
    return '$_imageBaseUrl$posterPath';
  }
  
  Future<Map<String, dynamic>?> getMovieDetails(int movieId) async {
     if (_apiKey == 'YOUR_TMDB_API_KEY') return null;

    try {
      final uri = Uri.parse('$_baseUrl/movie/$movieId').replace(queryParameters: {
        'api_key': _apiKey,
        'language': 'it-IT',
        'append_to_response': 'credits',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error getting TMDB details: $e');
    }
    return null;
  }
}
