class Movie {
  final String title;
  final String? detailsUrl;
  String? posterUrl;
  String? director;
  String? cast;
  String? plot;
  final String? specialEvent;

  Movie({
    required this.title,
    this.detailsUrl,
    this.posterUrl,
    this.director,
    this.cast,
    this.plot,
    this.specialEvent,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'],
      detailsUrl: json['details_url'],
      posterUrl: json['poster_url'],
      director: json['director'],
      cast: json['cast'],
      plot: json['plot'],
      specialEvent: json['special_event'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'details_url': detailsUrl,
      'poster_url': posterUrl,
      'director': director,
      'cast': cast,
      'plot': plot,
      'special_event': specialEvent,
    };
  }
}

class ShowTime {
  final String time;
  final String? bookingUrl;

  ShowTime({required this.time, this.bookingUrl});

  factory ShowTime.fromJson(Map<String, dynamic> json) {
    return ShowTime(
      time: json['time'],
      bookingUrl: json['booking_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'booking_url': bookingUrl,
    };
  }
}

class CinemaAvailability {
  final String cinemaName;
  final String date;
  final List<ShowTime> showtimes;
  final String? version;
  final String? detailsUrl;

  CinemaAvailability({
    required this.cinemaName,
    required this.date,
    required this.showtimes,
    this.version,
    this.detailsUrl,
  });

  factory CinemaAvailability.fromJson(Map<String, dynamic> json) {
    return CinemaAvailability(
      cinemaName: json['cinema_name'],
      date: json['date'],
      showtimes: (json['showtimes'] as List)
          .map((e) => ShowTime.fromJson(e))
          .toList(),
      version: json['version'],
      detailsUrl: json['details_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cinema_name': cinemaName,
      'date': date,
      'showtimes': showtimes.map((e) => e.toJson()).toList(),
      'version': version,
      'details_url': detailsUrl,
    };
  }
}

class MovieAvailability {
  final Movie movie;
  final List<CinemaAvailability> cinemas;

  MovieAvailability({required this.movie, required this.cinemas});

  factory MovieAvailability.fromJson(Map<String, dynamic> json) {
    return MovieAvailability(
      movie: Movie.fromJson(json['movie']),
      cinemas: (json['cinemas'] as List)
          .map((e) => CinemaAvailability.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movie': movie.toJson(),
      'cinemas': cinemas.map((e) => e.toJson()).toList(),
    };
  }
}
