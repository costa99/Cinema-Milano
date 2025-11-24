import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/tmdb_service.dart';
import '../services/favorites_service.dart';
import '../services/theme_service.dart';
import 'cinema_availability_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class MovieListScreen extends StatefulWidget {
  final ThemeController themeController;

  const MovieListScreen({super.key, required this.themeController});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late Future<List<MovieAvailability>> _moviesFuture;
  final ApiService _apiService = ApiService();
  final TMDBService _tmdbService = TMDBService();
  final FavoritesService _favoritesService = FavoritesService();
  Set<String> _selectedCinemas = {};
  Set<String> _favoriteMovieTitles = {};
  bool _showOnlyToday = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _posterLoadingStatus = {}; // Track which posters are being loaded

  @override
  void initState() {
    super.initState();
    print('=== MovieListScreen initState called ===');
    _refreshMovies();
    _loadFavorites();
  }

  void _refreshMovies() {
    setState(() {
      _moviesFuture = _apiService.getMovies(date: _showOnlyToday ? 'today' : null);
    });
    _loadPostersWhenReady();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteMovieTitles = favorites.map((m) => m.movie.title).toSet();
      });
    }
  }

  void _loadPostersWhenReady() async {
    try {
      final movies = await _moviesFuture;
      print('Movies loaded, starting poster loading for ${movies.length} movies');
      _loadPostersAsync(movies);
    } catch (e) {
      print('Error loading movies: $e');
    }
  }

  Future<void> _loadPostersAsync(List<MovieAvailability> movies) async {
    print('Starting to load ${movies.length} posters asynchronously...');
    
    for (var movieAvail in movies) {
      if (movieAvail.movie.posterUrl == null) {
        final movieTitle = movieAvail.movie.title;
        if (_posterLoadingStatus[movieTitle] == true) continue; // Already loading
        
        _posterLoadingStatus[movieTitle] = true;
        
        // Fetch poster from TMDB
        try {
          print('Searching TMDB for: $movieTitle');
          // Clean title for better search results (remove (O.V.), etc.)
          final cleanTitle = movieTitle.replaceAll(RegExp(r'\(.*?\)'), '').trim();
          
          final tmdbResult = await _tmdbService.searchMovie(cleanTitle);
          
          if (tmdbResult != null) {
            final posterPath = tmdbResult['poster_path'];
            final posterUrl = _tmdbService.getPosterUrl(posterPath);
            
            if (posterUrl != null) {
              print('Got TMDB poster for $movieTitle: $posterUrl');
              if (mounted) {
                setState(() {
                  movieAvail.movie.posterUrl = posterUrl;
                  // We could also update plot if available
                  if (movieAvail.movie.plot == null && tmdbResult['overview'] != null) {
                     movieAvail.movie.plot = tmdbResult['overview'];
                  }
                });
              }
            }
          } else {
            print('No TMDB result for $movieTitle, falling back to backend');
            _fetchBackendPoster(movieAvail);
          }
        } catch (e) {
          print('Error loading poster for $movieTitle from TMDB: $e');
          _fetchBackendPoster(movieAvail);
        }
      }
    }
    print('Finished loading posters');
  }

  Future<void> _fetchBackendPoster(MovieAvailability movieAvail) async {
    if (movieAvail.movie.detailsUrl == null) return;
    
    try {
      print('Fetching fallback poster from backend for: ${movieAvail.movie.title}');
      final cinemaName = movieAvail.cinemas.first.cinemaName;
      final details = await _apiService.getMovieDetails(
        movieAvail.movie.detailsUrl!,
        cinemaName,
      );
      
      if (details['poster_url'] != null) {
        print('Got backend poster for ${movieAvail.movie.title}: ${details['poster_url']}');
        if (mounted) {
          setState(() {
            movieAvail.movie.posterUrl = details['poster_url'];
          });
        }
      }
    } catch (e) {
      print('Error loading backend poster for ${movieAvail.movie.title}: $e');
    }
  }

  List<String> _getUniqueCinemas(List<MovieAvailability> movies) {
    final cinemas = <String>{'All'};
    for (var movie in movies) {
      for (var cinema in movie.cinemas) {
        cinemas.add(cinema.cinemaName);
      }
    }
    return cinemas.toList()..sort();
  }

  List<MovieAvailability> _filterMovies(List<MovieAvailability> movies) {
    try {
      var filtered = movies;
      
      // Filter by cinema
      if (_selectedCinemas.isNotEmpty) {
        filtered = filtered.where((movie) {
          return movie.cinemas.any((c) => _selectedCinemas.contains(c.cinemaName));
        }).toList();
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final normalizedQuery = query.replaceAll(' ', '');
        
        if (query.isNotEmpty) {
          filtered = filtered.where((movie) {
            final title = movie.movie.title.toLowerCase();
            final normalizedTitle = title.replaceAll(' ', '');
            
            // Check both original (with spaces respected) and normalized (ignoring spaces)
            // This handles "L'uovo" vs "L' uovo"
            return title.contains(query) || normalizedTitle.contains(normalizedQuery);
          }).toList();
        }
      }
  
      // Filter by "Today" - Handled by Backend now!
      // if (_showOnlyToday) { ... }
      
      return filtered;
    } catch (e) {
      print('Error filtering movies: $e');
      return []; // Return empty list on error to avoid crash, or return 'movies' to show all? 
                 // Empty list is safer as it indicates something went wrong but keeps UI stable.
    }
  }

  void _showCinemaFilterDialog(List<String> allCinemas) {
    final cinemas = allCinemas.where((c) => c != 'All').toList();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Cinemas'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: cinemas.map((cinema) {
                    final isSelected = _selectedCinemas.contains(cinema);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(cinema),
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            _selectedCinemas.add(cinema);
                          } else {
                            _selectedCinemas.remove(cinema);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Clear All'),
                  onPressed: () {
                    setStateDialog(() {
                      _selectedCinemas.clear();
                    });
                  },
                ),
                TextButton(
                  child: const Text('Done'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to determine if a movie is "coming soon" (7+ days away)
  bool _isComingSoon(MovieAvailability movieAvail) {
    final now = DateTime.now();
    final cutoffDate = now.add(const Duration(days: 7));
    
    for (var cinema in movieAvail.cinemas) {
      try {
        // Parse the date string (format: YYYY-MM-DD or "Today")
        DateTime? showDate;
        if (cinema.date.toLowerCase() == 'today') {
          showDate = now;
        } else {
          showDate = DateTime.tryParse(cinema.date);
        }
        
        // If any showtime is within the next 7 days, it's "now showing"
        if (showDate != null && showDate.isBefore(cutoffDate)) {
          return false;
        }
      } catch (e) {
        print('Error parsing date ${cinema.date}: $e');
      }
    }
    
    // If all showtimes are 7+ days away (or we couldn't parse any), it's "coming soon"
    return true;
  }

  // Split movies into "Now Showing" and "Coming Soon"
  Map<String, List<MovieAvailability>> _splitMoviesByDate(List<MovieAvailability> movies) {
    final nowShowing = <MovieAvailability>[];
    final comingSoon = <MovieAvailability>[];
    
    for (var movie in movies) {
      if (_isComingSoon(movie)) {
        comingSoon.add(movie);
      } else {
        nowShowing.add(movie);
      }
    }
    
    return {
      'nowShowing': nowShowing,
      'comingSoon': comingSoon,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Movies'),
          actions: [
            FutureBuilder<List<MovieAvailability>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final cinemas = _getUniqueCinemas(snapshot.data!);
                
                return IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showCinemaFilterDialog(cinemas),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refreshMovies();
              },
            ),
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                ).then((_) => _loadFavorites());
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(themeController: widget.themeController),
                  ),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<List<MovieAvailability>>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No movies found.'));
            }

            final allMovies = snapshot.data!;
            final movies = _filterMovies(allMovies);

            if (movies.isEmpty) {
               if (_searchQuery.isNotEmpty) {
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text('No movies found for "$_searchQuery"'),
                       const SizedBox(height: 16),
                       ElevatedButton.icon(
                         onPressed: () {
                           setState(() {
                             _searchController.clear();
                             _searchQuery = '';
                           });
                         },
                         icon: const Icon(Icons.clear),
                         label: const Text('Clear Search'),
                       ),
                     ],
                   ),
                 );
               }
               return const Center(child: Text('No movies found for this filter.'));
            }

            // Split movies by date
            final splitMovies = _splitMoviesByDate(movies);
            final nowShowing = splitMovies['nowShowing']!;
            final comingSoon = splitMovies['comingSoon']!;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 150.0,
                    floating: true,
                    pinned: false,
                    snap: true,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search bar and Today toggle
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search movies...',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                    _searchQuery = '';
                                                  });
                                                },
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        filled: true,
                                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Today', style: TextStyle(fontSize: 10)),
                                      Switch(
                                        value: _showOnlyToday,
                                        onChanged: (value) {
                                          setState(() {
                                            _showOnlyToday = value;
                                            _refreshMovies();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Tab bar
                            const TabBar(
                              tabs: [
                                Tab(text: 'Now Showing', icon: Icon(Icons.play_circle_outline)),
                                Tab(text: 'Coming Soon', icon: Icon(Icons.upcoming)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedCinemas.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Chip(
                          label: Text('Filtering by: ${_selectedCinemas.length} cinemas'),
                          onDeleted: () {
                            setState(() {
                              _selectedCinemas.clear();
                            });
                          },
                        ),
                      ),
                    ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildMovieGrid(nowShowing),
                  _buildMovieGrid(comingSoon),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMovieGrid(List<MovieAvailability> movies) {
    if (movies.isEmpty) {
      return const Center(child: Text('No movies in this category.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movieAvail = movies[index];
        final movie = movieAvail.movie;

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CinemaAvailabilityScreen(movieAvailability: movieAvail),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      movie.posterUrl != null
                          ? Image.network(
                              movie.posterUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.movie, size: 50),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.movie, size: 50),
                            ),

                      if (movie.specialEvent != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movie.specialEvent!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () async {
                            await _favoritesService.toggleFavorite(movieAvail);
                            await _loadFavorites();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _favoriteMovieTitles.contains(movie.title)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _favoriteMovieTitles.contains(movie.title)
                                  ? Colors.red
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available at: ${movieAvail.cinemas.map((c) => c.cinemaName).join(', ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
