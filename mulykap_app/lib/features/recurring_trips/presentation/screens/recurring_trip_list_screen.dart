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
import 'package:mulykap_app/features/recurring_trips/presentation/screens/trip_generation_screen.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/widgets/trip_generation_dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/widgets/recurring_trip_edit_dialog.dart';

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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Rafraîchir les données',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: BlocConsumer<RecurringTripBloc, RecurringTripState>(
        listener: (context, state) {
          // Ne pas traiter les états de chargement
          if (state.isLoading) return;
          
          // En cas d'erreur, afficher un message
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          // Si l'opération est réussie, mettre à jour le calendrier
          setState(() {
            _buildEventsByDay(state.trips);
          });
        },
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
          
          // Construire les événements par jour (maintenant fait dans le listener ci-dessus)
          // _buildEventsByDay(trips);

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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton pour générer des voyages à partir de tous les modèles récurrents
          FloatingActionButton.extended(
            heroTag: 'generate_all_trips',
            onPressed: () {
              TripGenerationDialog.show(context);
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('Générer voyages'),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          // Bouton pour créer un nouveau modèle de voyage récurrent
          FloatingActionButton(
            heroTag: 'add_recurring_trip',
            onPressed: _createNewTrip,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _buildEventsByDay(List<RecurringTripModel> trips) {
    _eventsByDay = {};
    
    // Pour chaque voyage récurrent
    for (var trip in trips) {
      // Ignorer les voyages inactifs (mais les garder dans la liste)
      if (!trip.isActive) continue;
      
      // Dates de validité
      final DateTime startDate = trip.validFrom;
      final DateTime endDate = trip.validUntil ?? DateTime(2100); // Date très lointaine si pas définie
      
      // Pour chaque jour de la semaine où le voyage est programmé
      for (var weekday in trip.weekdays) {
        // Trouver la première occurrence après la date de début
        DateTime date = _findFirstOccurrenceAfterDate(weekday, startDate);
        
        // Générer toutes les occurrences jusqu'à la date de fin de validité
        while (!date.isAfter(endDate)) {
          // Normaliser la date pour éviter les problèmes d'heure
          final normalizedDate = DateTime(date.year, date.month, date.day);
          
          // Ajouter l'événement à la date
          if (_eventsByDay[normalizedDate] == null) {
            _eventsByDay[normalizedDate] = [];
          }
          
          // Éviter les doublons
          if (!_eventsByDay[normalizedDate]!.any((t) => t.id == trip.id)) {
            _eventsByDay[normalizedDate]!.add(trip);
          }
          
          // Passer à la semaine suivante
          date = date.add(const Duration(days: 7));
        }
      }
    }
  }

  // Trouve la première occurrence d'un jour de semaine spécifique à partir d'une date
  DateTime _findFirstOccurrenceAfterDate(int weekday, DateTime startDate) {
    // Créer une date sans composantes d'heure pour éviter les problèmes de comparaison
    DateTime date = DateTime(startDate.year, startDate.month, startDate.day);
    
    // Récupérer le jour de la semaine de la date de début (1 = lundi, 7 = dimanche)
    int dayOfWeek = date.weekday;
    
    // Calculer le nombre de jours à ajouter pour atteindre le jour de la semaine cible
    int daysToAdd = 0;
    
    if (weekday == dayOfWeek) {
      // Si c'est le même jour, pas besoin d'ajouter des jours
      daysToAdd = 0;
    } else if (weekday > dayOfWeek) {
      // Si le jour cible est plus tard dans la semaine
      daysToAdd = weekday - dayOfWeek;
    } else {
      // Si le jour cible est plus tôt dans la semaine, passer à la semaine suivante
      daysToAdd = 7 - dayOfWeek + weekday;
    }
    
    // Retourner la date avec les jours ajoutés
    return date.add(Duration(days: daysToAdd));
  }

  // Trouve la prochaine occurrence d'un jour de la semaine à partir d'aujourd'hui
  DateTime _getNextWeekday(int weekday) {
    // Utiliser la date actuelle comme référence
    return _findFirstOccurrenceAfterDate(weekday, DateTime.now());
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
                  onGenerate: () {
                    TripGenerationDialog.show(
                      context,
                      recurringTripId: trip.id,
                    );
                  },
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
              lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
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
                setState(() {
                  _focusedDay = focusedDay;
                });
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
    // Normaliser la date d'entrée sans les composantes d'heure
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    // Vérifier si ce jour a des événements
    if (_eventsByDay.containsKey(normalizedDay)) {
      return _eventsByDay[normalizedDay] ?? [];
    }
    
    // Parcourir les clés pour trouver une correspondance
    for (final DateTime eventDay in _eventsByDay.keys) {
      if (eventDay.year == normalizedDay.year && 
          eventDay.month == normalizedDay.month && 
          eventDay.day == normalizedDay.day) {
        return _eventsByDay[eventDay] ?? [];
      }
    }
    
    return [];
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

  // Méthode pour appliquer les filtres et rafraîchir les données
  void _applyFilter(RecurrenceType? type) {
    // Afficher un message indiquant le filtrage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(type != null 
            ? 'Filtrage par ${type.displayName}...' 
            : 'Réinitialisation des filtres...'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Mettre à jour le type sélectionné
    setState(() {
      _selectedType = type;
    });
    
    // Appliquer le filtre au BLoC
    if (type != null) {
      context.read<RecurringTripBloc>().add(RecurringTripFilterByType(type));
    } else {
      context.read<RecurringTripBloc>().add(RecurringTripResetFilters());
    }
    
    // Forcer le rafraîchissement des données
    Future.delayed(const Duration(milliseconds: 300), _refreshData);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Utiliser une variable locale pour le type sélectionné dans cette boîte de dialogue
        RecurrenceType? localSelectedType = _selectedType;
        
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
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
                      final isSelected = localSelectedType == type;
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                        onSelected: (selected) {
                          setSheetState(() {
                            localSelectedType = selected ? type : null;
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
                          setSheetState(() {
                            localSelectedType = null;
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilter(localSelectedType);
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

  void _editTrip(RecurringTripModel trip) async {
    try {
      // Ouvrir la boîte de dialogue d'édition et récupérer si un voyage a été mis à jour
      bool tripUpdated = await RecurringTripEditDialog.show(context, trip);
      
      // Recharger explicitement les données si un voyage a été mis à jour
      if (mounted && tripUpdated) {
        _refreshData();
      }
    } catch (e) {
      // Gérer les erreurs potentielles
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'édition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createNewTrip() async {
    // Attendre que la boîte de dialogue se ferme et récupérer l'information sur la création
    bool tripCreated = await RecurringTripCreateDialog.show(context);
    
    // Recharger explicitement les données si un voyage a été créé
    if (mounted && tripCreated) {
      _refreshData();
    }
  }

  void _confirmDeleteTrip(RecurringTripModel trip) {
    // Capturer le contexte qui a accès au bloc avant d'ouvrir le dialogue
    final BuildContext outerContext = context;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce voyage récurrent?'),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer ce voyage récurrent?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              
              // Afficher un indicateur de chargement
              ScaffoldMessenger.of(outerContext).showSnackBar(
                const SnackBar(
                  content: Text('Suppression en cours...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // Utiliser le contexte externe qui a accès au bloc
              outerContext.read<RecurringTripBloc>().add(RecurringTripDelete(trip.id));
              
              // Attendre un instant pour permettre la suppression en base de données
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _refreshData();
                }
              });
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmToggleStatus(RecurringTripModel trip) {
    // Capturer le contexte qui a accès au bloc avant d'ouvrir le dialogue
    final BuildContext outerContext = context;
    
    final newStatus = !trip.isActive;
    final message = newStatus
        ? 'Voulez-vous activer ce voyage récurrent?'
        : 'Voulez-vous désactiver ce voyage récurrent?';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newStatus ? 'Activer le voyage?' : 'Désactiver le voyage?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              
              // Afficher un indicateur de statut
              ScaffoldMessenger.of(outerContext).showSnackBar(
                SnackBar(
                  content: Text(newStatus ? 'Activation en cours...' : 'Désactivation en cours...'),
                  duration: const Duration(seconds: 1),
                ),
              );
              
              // Utiliser le contexte externe qui a accès au bloc
              outerContext.read<RecurringTripBloc>().add(
                RecurringTripToggleStatus(
                  id: trip.id,
                  isActive: newStatus,
                ),
              );
              
              // Attendre un instant pour permettre la mise à jour en base de données
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _refreshData();
                }
              });
            },
            child: Text(newStatus ? 'Activer' : 'Désactiver'),
          ),
        ],
      ),
    );
  }

  // Méthode pour rafraîchir explicitement les données
  void _refreshData() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rafraîchissement en cours...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // S'assurer que nous sommes toujours montés et que le contexte est valide
    if (mounted) {
      context.read<RecurringTripBloc>().add(RecurringTripLoadAll());
    }
  }
} 