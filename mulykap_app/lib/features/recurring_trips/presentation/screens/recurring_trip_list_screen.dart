import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/core/presentation/widgets/error_message.dart';
import 'package:mulykap_app/core/presentation/widgets/loading_spinner.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_event.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_state.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/widgets/recurring_trip_item.dart';
import 'package:mulykap_app/core/presentation/router/app_router.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/widgets/recurring_trip_create_dialog.dart';
import 'package:mulykap_app/features/recurring_trips/data/repositories/recurring_trip_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class RecurringTripListScreen extends StatefulWidget {
  const RecurringTripListScreen({Key? key}) : super(key: key);

  @override
  State<RecurringTripListScreen> createState() => _RecurringTripListScreenState();
}

class _RecurringTripListScreenState extends State<RecurringTripListScreen> {
  RecurrenceType? _selectedType;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _showCalendarView = true; // Pour montrer/cacher le calendrier sur mobile
  Map<DateTime, List<RecurringTripModel>> _eventsByDay = {};
  bool _isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les données de localisation
    _initializeLocale();
    // Charger les voyages récurrents au démarrage
    _loadRecurringTrips();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('fr_FR', null);
    setState(() {
      _isLocaleInitialized = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les voyages récurrents à chaque changement de dépendances
    // (par exemple après la navigation)
    _loadRecurringTrips();
  }

  void _loadRecurringTrips() {
    // Utiliser un microtask pour s'assurer que cela se produit après le build
    Future.microtask(() {
      if (mounted) {
        context.read<RecurringTripBloc>().add(RecurringTripLoadAll());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = MediaQuery.of(context).size.width >= 768;
    
    if (!_isLocaleInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Voyages Récurrents'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation des données de localisation...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyages Récurrents'),
        actions: [
          if (!isTabletOrDesktop)
            IconButton(
              icon: Icon(_showCalendarView ? Icons.list : Icons.calendar_month),
              onPressed: () {
                setState(() {
                  _showCalendarView = !_showCalendarView;
                });
              },
              tooltip: _showCalendarView ? 'Afficher la liste' : 'Afficher le calendrier',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: BlocBuilder<RecurringTripBloc, RecurringTripState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const LoadingSpinner();
          }

          if (state.isError) {
            return ErrorMessage(
              message: state.error ?? 'Une erreur est survenue',
              onRetry: () => context.read<RecurringTripBloc>().add(RecurringTripLoadAll()),
            );
          }

          final trips = state.filteredTrips;
          
          // Construire les événements par jour
          _buildEventsByDay(trips);

          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.repeat,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.hasFilters
                        ? 'Aucun voyage récurrent ne correspond aux filtres'
                        : 'Aucun voyage récurrent disponible',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  if (state.hasFilters) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Réinitialiser les filtres'),
                      onPressed: () {
                        setState(() {
                          _selectedType = null;
                        });
                        context.read<RecurringTripBloc>().add(RecurringTripResetFilters());
                      },
                    ),
                  ],
                ],
              ),
            );
          }

          // View responsif - soit calendrier soit liste sur mobile
          if (!isTabletOrDesktop) {
            return _showCalendarView 
              ? _buildCalendarView(context)
              : _buildListView(context, state, trips);
          }
          
          // Vue tablette/bureau avec écran divisé
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Liste à gauche (1/2 de l'écran)
              Expanded(
                flex: 1,
                child: _buildListView(context, state, trips),
              ),
              // Séparateur vertical
              const VerticalDivider(width: 1, thickness: 1),
              // Calendrier à droite (1/2 de l'écran)
              Expanded(
                flex: 1,
                child: _buildCalendarView(context),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTrip,
        tooltip: 'Ajouter un voyage récurrent',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _buildEventsByDay(List<RecurringTripModel> trips) {
    _eventsByDay = {};
    
    // Pour chaque voyage récurrent
    for (var trip in trips) {
      // Pour chaque jour de la semaine où le voyage est programmé
      for (var weekday in trip.weekdays) {
        // Trouver la prochaine occurrence de ce jour de la semaine
        DateTime date = _getNextWeekday(weekday);
        
        // Ajouter le voyage à ce jour
        if (_eventsByDay[date] == null) {
          _eventsByDay[date] = [];
        }
        _eventsByDay[date]!.add(trip);
        
        // Ajouter également pour les 8 semaines suivantes
        for (int i = 1; i <= 8; i++) {
          DateTime futureDate = date.add(Duration(days: 7 * i));
          if (futureDate.isBefore(trip.validUntil ?? DateTime(2100))) { // Si avant la date de fin
            if (_eventsByDay[futureDate] == null) {
              _eventsByDay[futureDate] = [];
            }
            _eventsByDay[futureDate]!.add(trip);
          }
        }
      }
    }
  }

  // Widget pour la vue liste
  Widget _buildListView(BuildContext context, RecurringTripState state, List<RecurringTripModel> trips) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RecurringTripBloc>().add(RecurringTripLoadAll());
      },
      child: Column(
        children: [
          if (state.hasFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16),
                  const SizedBox(width: 8),
                  const Text('Filtres actifs:'),
                  const SizedBox(width: 8),
                  if (state.filterType != null)
                    Chip(
                      label: Text(state.filterType!.displayName),
                      deleteIcon: const Icon(Icons.clear, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedType = null;
                        });
                        context.read<RecurringTripBloc>().add(RecurringTripResetFilters());
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return RecurringTripItem(
                  trip: trip,
                  onTap: () => _navigateToTripDetail(trip),
                  onEdit: () => _editTrip(trip),
                  onDelete: () => _confirmDeleteTrip(trip),
                  onToggleStatus: () => _confirmToggleStatus(trip),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la vue calendrier
  Widget _buildCalendarView(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                titleCentered: true,
                titleTextStyle: const TextStyle(fontSize: 18.0),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final eventsForDay = _getEventsForDay(date);
                  if (eventsForDay.isEmpty) return const SizedBox.shrink();
                  
                  return Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      width: 16,
                      height: 16,
                      child: Center(
                        child: Text(
                          '${eventsForDay.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              eventLoader: (day) {
                return _getEventsForDay(day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red[300]),
                outsideDaysVisible: false,
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildEventsList(context),
        ),
      ],
    );
  }

  // Récupère les événements pour un jour donné
  List<RecurringTripModel> _getEventsForDay(DateTime day) {
    // Vérifier si ce jour a des événements
    for (DateTime eventDay in _eventsByDay.keys) {
      if (isSameDay(eventDay, day)) {
        return _eventsByDay[eventDay] ?? [];
      }
    }
    return [];
  }

  // Trouve la prochaine occurrence d'un jour de la semaine spécifique
  DateTime _getNextWeekday(int weekday) {
    DateTime date = DateTime.now();
    
    // Récupérer l'index du jour de la semaine (1 = lundi, 7 = dimanche)
    int currentWeekday = date.weekday;
    
    // Calculer le nombre de jours à ajouter
    int daysToAdd = weekday - currentWeekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7; // Si c'est aujourd'hui ou avant, on va à la semaine prochaine
    }
    
    // Ajouter les jours nécessaires
    return date.add(Duration(days: daysToAdd));
  }
  
  // Widget pour afficher la liste des voyages pour un jour sélectionné
  Widget _buildEventsList(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final dateFormatter = DateFormat.yMMMMEEEEd('fr_FR');
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun voyage le ${dateFormatter.format(_selectedDay)}',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormatter.format(_selectedDay).toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${events.length} voyage${events.length > 1 ? 's' : ''} prévu${events.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final trip = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.directions_bus,
                    color: trip.isActive ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  title: Row(
                    children: [
                      Text(
                        '${trip.departureTime} - ${trip.arrivalTime}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: trip.isActive ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      trip.isActive
                        ? Icon(Icons.check_circle, color: Colors.green, size: 16)
                        : Icon(Icons.cancel, color: Colors.red, size: 16),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.routeName ?? 'Itinéraire inconnu'),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${trip.recurrenceType.displayName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _navigateToTripDetail(trip),
                  ),
                  onTap: () => _navigateToTripDetail(trip),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrer par type de récurrence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: RecurrenceType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedType = null;
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (_selectedType != null) {
                            context.read<RecurringTripBloc>().add(
                                  RecurringTripFilterByType(_selectedType!),
                                );
                          } else {
                            context.read<RecurringTripBloc>().add(RecurringTripResetFilters());
                          }
                        },
                        child: const Text('Appliquer'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToTripDetail(RecurringTripModel trip) {
    // TODO: Implémenter la navigation vers l'écran de détail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Afficher les détails du voyage récurrent: ${trip.id}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _editTrip(RecurringTripModel trip) {
    // TODO: Implémenter la modification d'un voyage récurrent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modifier le voyage récurrent: ${trip.id}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _createNewTrip() async {
    // Attendre que la boîte de dialogue se ferme
    await RecurringTripCreateDialog.show(context);
    
    // Recharger explicitement la liste après la fermeture
    if (mounted) {
      // Vérification si le widget est toujours monté pour éviter les erreurs
      context.read<RecurringTripBloc>().add(RecurringTripLoadAll());
    }
  }

  void _confirmDeleteTrip(RecurringTripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce voyage récurrent?'),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer ce voyage récurrent?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RecurringTripBloc>().add(RecurringTripDelete(trip.id));
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmToggleStatus(RecurringTripModel trip) {
    final newStatus = !trip.isActive;
    final message = newStatus
        ? 'Voulez-vous activer ce voyage récurrent?'
        : 'Voulez-vous désactiver ce voyage récurrent?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Activer le voyage?' : 'Désactiver le voyage?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RecurringTripBloc>().add(
                    RecurringTripToggleStatus(
                      id: trip.id,
                      isActive: newStatus,
                    ),
                  );
            },
            child: Text(newStatus ? 'Activer' : 'Désactiver'),
          ),
        ],
      ),
    );
  }
} 