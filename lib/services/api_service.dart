import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiService {
  // Production domain with HTTPS
  static const String _productionDomain = 'homescrapy.xyz';
  
  // For local development, uncomment one of these:
  // static const String _localHost = '10.0.2.2:8000'; // Android Emulator
  // static const String _localHost = '192.168.1.x:8000'; // Physical device on local network
  
  String get baseUrl {
    // Production: HTTPS with domain
    return 'https://$_productionDomain';
    
    // For local development, uncomment this instead:
    // return 'http://$_localHost';
  }

  Future<List<MovieAvailability>> getMovies({String? date}) async {
    try {
      var uri = Uri.parse('$baseUrl/movies');
      if (date != null) {
        uri = uri.replace(queryParameters: {'date': date});
      }
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MovieAvailability.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
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
