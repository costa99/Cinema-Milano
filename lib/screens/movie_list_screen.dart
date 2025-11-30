import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/theme_service.dart';
import 'cinema_availability_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

import 'package:intl/intl.dart';

class MovieListScreen extends StatefulWidget {
  final ThemeController themeController;

  const MovieListScreen({super.key, required this.themeController});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> with SingleTickerProviderStateMixin {
  late Future<List<List<MovieAvailability>>> _moviesFuture;
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();
  Set<String> _selectedCinemas = {};
  Set<String> _favoriteMovieTitles = {};
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    print('=== MovieListScreen initState called ===');
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to show/hide date picker
    });
    _refreshMovies();
    _loadFavorites();
  }

  DateTime _getEndOfWeek() {
    final now = DateTime.now();
    // Calculate days until Sunday (7 = Sunday in DateTime.weekday)
    final daysUntilSunday = DateTime.sunday - now.weekday;
    // If today is Sunday, daysUntilSunday will be 0
    final endOfWeek = now.add(Duration(days: daysUntilSunday));
    // Return end of day on Sunday
    return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
  }

  void _refreshMovies() {
    setState(() {
    setState(() {
      _moviesFuture = Future.wait([
        _apiService.getCurrentMovies(),
        _apiService.getComingSoonMovies(),
      ]);
    });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final endOfWeek = _getEndOfWeek();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: endOfWeek,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _refreshMovies();
    }
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteMovieTitles = favorites.map((m) => m.movie.title).toSet();
      });
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

  List<MovieAvailability> _filterMovies(List<MovieAvailability> movies, {bool filterByDate = false}) {
    try {
      var filtered = movies;
      
      // Filter by date if requested (for Now Showing)
      if (filterByDate) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        filtered = filtered.where((movie) {
          // Check if any cinema has showtimes on the selected date
          return movie.cinemas.any((cinema) => cinema.date == dateStr);
        }).map((movie) {
          // Create a new MovieAvailability with only the relevant cinemas
          final relevantCinemas = movie.cinemas.where((cinema) => cinema.date == dateStr).toList();
          return MovieAvailability(
            movie: movie.movie,
            cinemas: relevantCinemas,
          );
        }).toList();
      }

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
  
      return filtered;
    } catch (e) {
      print('Error filtering movies: $e');
      return []; // Return empty list on error to avoid crash
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
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Movies'),
          actions: [
            FutureBuilder<List<List<MovieAvailability>>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final allMovies = snapshot.data!.expand((l) => l).toList();
                final cinemas = _getUniqueCinemas(allMovies);
                
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
        body: FutureBuilder<List<List<MovieAvailability>>>(
          future: _moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No movies found.'));
            }

            final nowShowingAll = snapshot.data![0];
            final comingSoonAll = snapshot.data![1];

            final nowShowing = _filterMovies(nowShowingAll, filterByDate: true);
            final comingSoon = _filterMovies(comingSoonAll);

            if (nowShowing.isEmpty && comingSoon.isEmpty) {
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
                            // Search bar and Date Picker
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
                                  // Date Picker Button - Only show on "Now Showing" tab
                                  if (_tabController.index == 0)
                                    InkWell(
                                      onTap: () => _selectDate(context),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 20),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('dd/MM').format(_selectedDate),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Tab bar
                            TabBar(
                              controller: _tabController,
                              tabs: const [
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
                controller: _tabController,
                children: [
                  _buildMovieGrid(nowShowing, 'nowShowing'),
                  _buildMovieGrid(comingSoon, 'comingSoon'),
                ],
              ),
            );
          },
        ),
      );
  }



  Widget _buildMovieGrid(List<MovieAvailability> movies, String key) {
    if (movies.isEmpty) {
      return const Center(child: Text('No movies in this category.'));
    }

    return ScrollConfiguration(
      behavior: NoScrollbarBehavior(),
      child: GridView.builder(
        key: PageStorageKey(key),
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
    ),
    );
  }
}

class NoScrollbarBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
