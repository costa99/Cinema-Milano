import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/movie.dart';

class CinemaAvailabilityScreen extends StatefulWidget {
  final MovieAvailability movieAvailability;

  const CinemaAvailabilityScreen({super.key, required this.movieAvailability});

  @override
  State<CinemaAvailabilityScreen> createState() =>
      _CinemaAvailabilityScreenState();
}

class _CinemaAvailabilityScreenState extends State<CinemaAvailabilityScreen> {
  late MovieAvailability _movieAvailability;
  final Map<String, bool> _expandedCinemas = {};

  @override
  void initState() {
    super.initState();
    _movieAvailability = widget.movieAvailability;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMM').format(date); // e.g. "Saturday, 19 Apr"
    } catch (_) {
      return dateStr;
    }
  }

  DateTime _parseDate(String date) {
    final lower = date.toLowerCase().trim();
    if (lower == 'today' || lower == 'oggi') return DateTime.now();
    if (lower == 'tomorrow' || lower == 'domani') {
      return DateTime.now().add(const Duration(days: 1));
    }
    try {
      return DateTime.parse(date);
    } catch (_) {}
    // Try dd/MM/yyyy
    final slashParts = date.split('/');
    if (slashParts.length == 3) {
      try {
        return DateTime(
          int.parse(slashParts[2]),
          int.parse(slashParts[1]),
          int.parse(slashParts[0]),
        );
      } catch (_) {}
    }
    return DateTime.now();
  }

  Future<void> _addToCalendar(
    String cinemaName,
    String date,
    String time,
  ) async {
    try {
      final eventDate = _parseDate(date);

      // Parse the time (format: "HH:MM" or "HH:MM AM/PM")
      final timeParts = time.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(
          timeParts[1].split(' ')[0],
        ); // Remove AM/PM if present

        // Handle AM/PM if present
        if (time.toUpperCase().contains('PM') && hour != 12) {
          hour += 12;
        } else if (time.toUpperCase().contains('AM') && hour == 12) {
          hour = 0;
        }

        // Create the event date/time
        final eventDateTime = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          hour,
          minute,
        );

        // Create calendar event
        final Event event = Event(
          title: _movieAvailability.movie.title,
          description:
              'Movie at $cinemaName\n${_movieAvailability.movie.plot ?? ''}',
          location: cinemaName,
          startDate: eventDateTime,
          endDate: eventDateTime.add(
            const Duration(hours: 2),
          ), // Assume 2 hour duration
          allDay: false,
        );

        // Add to calendar
        await Add2Calendar.addEvent2Cal(event);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added to calendar: ${_movieAvailability.movie.title} at $time',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding to calendar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Map<String, List<CinemaAvailability>> _groupCinemasByName() {
    final Map<String, List<CinemaAvailability>> grouped = {};

    for (var cinema in _movieAvailability.cinemas) {
      // Create a unique key combining cinema name and version
      final key =
          '${cinema.cinemaName}${cinema.version != null ? ' - ${cinema.version}' : ''}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(cinema);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_movieAvailability.movie.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_movieAvailability.movie.posterUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        _movieAvailability.movie.posterUrl!,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.movie, size: 100),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 120,
                      height: 180,
                      child: Icon(Icons.movie, size: 100),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_movieAvailability.movie.director != null) ...[
                          const Text(
                            'Director:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_movieAvailability.movie.director!),
                          const SizedBox(height: 8),
                        ],
                        if (_movieAvailability.movie.cast != null) ...[
                          const Text(
                            'Cast:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_movieAvailability.movie.cast!),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_movieAvailability.movie.plot != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plot:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_movieAvailability.movie.plot!),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Showtimes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Long-press a showtime to add to calendar',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Cinemas and Showtimes (grouped by cinema)
            Builder(
              builder: (context) {
                final groupedCinemas = _groupCinemasByName();
                final cinemaNames = groupedCinemas.keys.toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cinemaNames.length,
                  itemBuilder: (context, index) {
                    final cinemaName = cinemaNames[index];
                    final cinemaAvailabilities = groupedCinemas[cinemaName]!;
                    final firstCinema = cinemaAvailabilities.first;

                    // Get booking URL from first showtime if available
                    final bookingUrl =
                        firstCinema.showtimes.isNotEmpty &&
                            firstCinema.showtimes.first.bookingUrl != null
                        ? firstCinema.showtimes.first.bookingUrl
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _expandedCinemas[cinemaName] =
                                      !(_expandedCinemas[cinemaName] ?? false);
                                });
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cinemaName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (firstCinema.version != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        firstCinema.version!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (bookingUrl != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _launchUrl(bookingUrl),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                  Icon(
                                    (_expandedCinemas[cinemaName] ?? false)
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ],
                              ),
                            ),
                            if (_expandedCinemas[cinemaName] ?? false) ...[
                              const SizedBox(height: 12),
                              // Display all dates for this cinema
                              ...cinemaAvailabilities.map((cinema) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(cinema.date),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 4.0,
                                        children: cinema.showtimes.map((
                                          showtime,
                                        ) {
                                          return InkWell(
                                            onLongPress: () {
                                              _addToCalendar(
                                                cinema.cinemaName,
                                                cinema.date,
                                                showtime.time,
                                              );
                                            },
                                            onTap: showtime.bookingUrl != null
                                                ? () => _launchUrl(
                                                    showtime.bookingUrl!,
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Chip(
                                              avatar: const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                              ),
                                              label: Text(showtime.time),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
