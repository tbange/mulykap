import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mulykap_app/core/presentation/widgets/error_message.dart';
import 'package:mulykap_app/core/presentation/widgets/loading_spinner.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/drivers/data/repositories/driver_repository.dart';
import 'package:mulykap_app/features/drivers/domain/models/driver_model.dart';
import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_bloc.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_event.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> with SingleTickerProviderStateMixin {
  // Variables pour les filtres
  DateTime? _selectedDate;
  TripStatus? _selectedStatus;
  
  // Variables pour le calendrier
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _showCalendarView = true; // Pour montrer/cacher le calendrier sur mobile
  Map<DateTime, List<TripModel>> _eventsByDay = {};
  bool _isLocaleInitialized = false;
  
  // Variables pour les chauffeurs et bus
  List<DriverModel> _drivers = [];
  List<BusModel> _buses = [];
  bool _isLoadingDrivers = false;
  bool _isLoadingBuses = false;
  
  // Contrôleurs
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialiser les données de localisation
    _initializeLocale();
    
    // Chargement initial des voyages
    _loadTrips();
    
    // Chargement des chauffeurs et des bus pour les assignations
    _loadDrivers();
    _loadBuses();
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
    // Recharger les voyages à chaque changement de dépendances
    _loadTrips();
  }
  
  void _loadTrips() {
    // Utiliser un microtask pour s'assurer que cela se produit après le build
    Future.microtask(() {
      if (mounted) {
        context.read<TripBloc>().add(TripLoadAll());
      }
    });
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
    });
    
    try {
      final driverRepository = DriverRepository(
        supabaseClient: Supabase.instance.client,
      );
      
      final drivers = await driverRepository.getAllDrivers();
      
      setState(() {
        _drivers = drivers;
        _isLoadingDrivers = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des chauffeurs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() {
        _isLoadingDrivers = false;
      });
    }
  }
  
  Future<void> _loadBuses() async {
    setState(() {
      _isLoadingBuses = true;
    });
    
    try {
      final busRepository = BusRepository(
        supabaseClient: Supabase.instance.client,
      );
      
      final buses = await busRepository.getAllBuses();
      
      setState(() {
        _buses = buses;
        _isLoadingBuses = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des bus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() {
        _isLoadingBuses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = MediaQuery.of(context).size.width >= 768;
    
    if (!_isLocaleInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Voyages'),
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
        title: const Text('Voyages'),
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
            tooltip: 'Filtrer par statut',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrer par date',
            onPressed: _selectDateFilter,
          ),
        ],
      ),
      body: BlocConsumer<TripBloc, TripState>(
        listener: (context, state) {
          if (state.isLoading) return;
          
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
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
              message: state.errorMessage ?? 'Une erreur est survenue',
              onRetry: () => context.read<TripBloc>().add(TripLoadAll()),
            );
          }

          final trips = state.filteredTrips;
          
          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_bus_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.hasFilters
                        ? 'Aucun voyage ne correspond aux filtres'
                        : 'Aucun voyage disponible',
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
                          _selectedDate = null;
                          _selectedStatus = null;
                        });
                        context.read<TripBloc>().add(TripResetFilters());
                      },
                    ),
                  ],
                ],
              ),
            );
          }

          if (!isTabletOrDesktop) {
            return _showCalendarView 
              ? _buildCalendarView(context)
              : _buildListView(context, state, trips);
          }
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildListView(context, state, trips),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                flex: 1,
                child: _buildCalendarView(context),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildTripCard(TripModel trip) {
    final bool needsDriver = trip.driverId == null;
    final bool needsBus = trip.busId == null;
    
    // Calculer le temps jusqu'au départ
    final now = DateTime.now();
    final Duration timeUntilDeparture = trip.departureTime.difference(now);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(trip.status).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trip.routeName ?? 'Itinéraire inconnu',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    trip.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(trip.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(trip.status).withOpacity(0.2),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          
          // Contenu de la carte
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de départ et d'arrivée
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Départ: ${_dateFormat.format(trip.departureTime)} à ${DateFormat('HH:mm').format(trip.departureTime)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Arrivée: ${_dateFormat.format(trip.arrivalTime)} à ${DateFormat('HH:mm').format(trip.arrivalTime)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Informations du bus
                Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.busPlate != null 
                            ? 'Bus: ${trip.busPlate}' 
                            : 'Bus: Non assigné',
                        style: TextStyle(
                          fontSize: 16,
                          color: needsBus ? Colors.red : null,
                          fontWeight: needsBus ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    if (needsBus)
                      ElevatedButton.icon(
                        onPressed: () => _showBusSelectionDialog(trip),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Assigner'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Informations du chauffeur
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.driverName != null && trip.driverName!.isNotEmpty
                            ? 'Chauffeur: ${trip.driverName}' 
                            : 'Chauffeur: Non assigné',
                        style: TextStyle(
                          fontSize: 16,
                          color: needsDriver ? Colors.red : null,
                          fontWeight: needsDriver ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    if (needsDriver)
                      ElevatedButton.icon(
                        onPressed: () => _showDriverSelectionDialog(trip),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Assigner'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Prix et informations supplémentaires
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prix: ${trip.basePrice.toInt()} FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (trip.status == TripStatus.planned && timeUntilDeparture.isNegative)
                      _buildActionButton(
                        'Démarrer',
                        Icons.play_arrow,
                        Colors.green,
                        () => _updateTripStatus(trip, TripStatus.in_progress),
                      ),
                    if (trip.status == TripStatus.in_progress)
                      _buildActionButton(
                        'Terminer',
                        Icons.check,
                        Colors.blue,
                        () => _updateTripStatus(trip, TripStatus.completed),
                      ),
                    if (trip.status == TripStatus.planned && timeUntilDeparture.inMinutes > 30)
                      _buildActionButton(
                        'Annuler',
                        Icons.cancel,
                        Colors.red,
                        () => _updateTripStatus(trip, TripStatus.cancelled),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.planned:
        return Colors.orange;
      case TripStatus.in_progress:
        return Colors.blue;
      case TripStatus.completed:
        return Colors.green;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildListView(BuildContext context, TripState state, List<TripModel> trips) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TripBloc>().add(TripLoadAll());
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
                  if (_selectedStatus != null)
                    Chip(
                      label: Text(_selectedStatus!.displayName),
                      deleteIcon: const Icon(Icons.clear, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = null;
                        });
                        context.read<TripBloc>().add(TripFilterByStatus(null));
                      },
                    ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                      deleteIcon: const Icon(Icons.clear, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedDate = null;
                        });
                        context.read<TripBloc>().add(TripFilterByDate(null));
                      },
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildTripCard(trip);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    // Capturer l'état actuel du filtre pour l'afficher correctement dans le bottomsheet
    final TripStatus? currentStatusFilter = _selectedStatus;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Initialiser l'état local avec le filtre actuel
            TripStatus? localSelectedStatus = currentStatusFilter;
            
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrer par statut',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildStatusFilterButton(
                          status: TripStatus.planned,
                          label: 'Programmé',
                          icon: Icons.schedule_outlined,
                          color: Colors.orange,
                          isSelected: localSelectedStatus == TripStatus.planned,
                          onTap: () {
                            setState(() {
                              localSelectedStatus = localSelectedStatus == TripStatus.planned 
                                  ? null 
                                  : TripStatus.planned;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusFilterButton(
                          status: TripStatus.in_progress,
                          label: 'En cours',
                          icon: Icons.directions_bus_outlined,
                          color: Colors.blue,
                          isSelected: localSelectedStatus == TripStatus.in_progress,
                          onTap: () {
                            setState(() {
                              localSelectedStatus = localSelectedStatus == TripStatus.in_progress 
                                  ? null 
                                  : TripStatus.in_progress;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildStatusFilterButton(
                          status: TripStatus.completed,
                          label: 'Terminé',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          isSelected: localSelectedStatus == TripStatus.completed,
                          onTap: () {
                            setState(() {
                              localSelectedStatus = localSelectedStatus == TripStatus.completed 
                                  ? null 
                                  : TripStatus.completed;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusFilterButton(
                          status: TripStatus.cancelled,
                          label: 'Annulé',
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                          isSelected: localSelectedStatus == TripStatus.cancelled,
                          onTap: () {
                            setState(() {
                              localSelectedStatus = localSelectedStatus == TripStatus.cancelled 
                                  ? null 
                                  : TripStatus.cancelled;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            localSelectedStatus = null;
                          });
                          
                          Navigator.pop(context);
                          
                          // Réinitialiser uniquement le filtre de statut
                          this.setState(() {
                            _selectedStatus = null;
                          });
                          
                          context.read<TripBloc>().add(
                            TripFilterByStatus(null),
                          );
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          
                          // Mettre à jour l'état local
                          this.setState(() {
                            _selectedStatus = localSelectedStatus;
                          });
                          
                          // Appliquer le filtre
                          context.read<TripBloc>().add(
                            TripFilterByStatus(localSelectedStatus),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
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

  Widget _buildStatusFilterButton({
    required TripStatus status,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateFilter() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      
      context.read<TripBloc>().add(TripFilterByDate(pickedDate));
    }
  }

  // Méthode pour construire les événements par jour à partir de la liste des voyages
  void _buildEventsByDay(List<TripModel> trips) {
    _eventsByDay = {};
    
    for (var trip in trips) {
      // Ignorer les voyages annulés
      if (trip.status == TripStatus.cancelled) continue;
      
      // Normaliser la date pour éviter les problèmes d'heure
      final departureDay = DateTime(
        trip.departureTime.year, 
        trip.departureTime.month, 
        trip.departureTime.day
      );
      
      if (_eventsByDay[departureDay] == null) {
        _eventsByDay[departureDay] = [];
      }
      
      if (!_eventsByDay[departureDay]!.any((t) => t.id == trip.id)) {
        _eventsByDay[departureDay]!.add(trip);
      }
    }
  }
  
  // Récupère les événements pour un jour donné
  List<TripModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    if (_eventsByDay.containsKey(normalizedDay)) {
      return _eventsByDay[normalizedDay] ?? [];
    }
    
    for (final DateTime eventDay in _eventsByDay.keys) {
      if (eventDay.year == normalizedDay.year && 
          eventDay.month == normalizedDay.month && 
          eventDay.day == normalizedDay.day) {
        return _eventsByDay[eventDay] ?? [];
      }
    }
    
    return [];
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
    
    if (mounted) {
      context.read<TripBloc>().add(TripLoadAll());
    }
  }

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
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'fr_FR',
              headerStyle: HeaderStyle(
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                titleCentered: true,
                titleTextStyle: const TextStyle(fontSize: 18.0),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red),
                markerSize: 8.0,
                markerMargin: EdgeInsets.symmetric(horizontal: 0.3),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.map((trip) {
                      final TripModel tripEvent = trip as TripModel;
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 0.3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(tripEvent.status),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                context.read<TripBloc>().add(TripFilterByDate(selectedDay));
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
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: _buildEventsForSelectedDay(),
        ),
      ],
    );
  }

  Widget _buildEventsForSelectedDay() {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Aucun voyage prévu pour ce jour',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final trip = events[index];
        return _buildTripCard(trip);
      },
    );
  }

  Future<void> _showBusSelectionDialog(TripModel trip) async {
    if (_isLoadingBuses) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement des bus en cours...'),
      ),
    );
      return;
  }

    if (_buses.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Aucun bus disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    String? selectedBusId;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sélectionner un bus'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: _buses.length,
                  itemBuilder: (context, index) {
                    final bus = _buses[index];
                    return RadioListTile<String>(
                      title: Text('${bus.licensePlate} (${bus.model})'),
                      subtitle: Text('Capacité: ${bus.capacity} sièges'),
                      value: bus.id,
                      groupValue: selectedBusId,
                      onChanged: (value) {
                        setState(() {
                          selectedBusId = value;
                        });
                      },
                    );
                  },
                );
              },
            ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
            ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
                
                if (selectedBusId != null) {
                  _assignBus(trip, selectedBusId!);
                }
              },
              child: const Text('Assigner'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showDriverSelectionDialog(TripModel trip) async {
    if (_isLoadingDrivers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement des chauffeurs en cours...'),
        ),
      );
      return;
    }
    
    if (_drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun chauffeur disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    String? selectedDriverId;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sélectionner un chauffeur'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: _drivers.length,
                  itemBuilder: (context, index) {
                    final driver = _drivers[index];
                    return RadioListTile<String>(
                      title: Text('${driver.firstName} ${driver.lastName}'),
                      subtitle: Text('Permis: ${driver.licenseNumber ?? "Non spécifié"}'),
                      value: driver.id,
                      groupValue: selectedDriverId,
                      onChanged: (value) {
                        setState(() {
                          selectedDriverId = value;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                
                if (selectedDriverId != null) {
                  _assignDriver(trip, selectedDriverId!);
                }
              },
              child: const Text('Assigner'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _assignBus(TripModel trip, String busId) async {
    final selectedBus = _buses.firstWhere((bus) => bus.id == busId);
    
    // Mettre à jour le voyage avec le nouveau bus
    context.read<TripBloc>().add(
      TripUpdate(
        trip.copyWith(
          busId: busId,
          busPlate: selectedBus.licensePlate,
        ),
      ),
    );
  }
  
  Future<void> _assignDriver(TripModel trip, String driverId) async {
    final selectedDriver = _drivers.firstWhere((driver) => driver.id == driverId);
    
    // Mettre à jour le voyage avec le nouveau chauffeur
    context.read<TripBloc>().add(
      TripUpdate(
        trip.copyWith(
          driverId: driverId,
          driverName: '${selectedDriver.firstName} ${selectedDriver.lastName}',
        ),
      ),
    );
  }
  
  Future<void> _updateTripStatus(TripModel trip, TripStatus newStatus) async {
    // Feedback visuel pour l'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mise à jour du statut en ${newStatus.displayName}...'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Utiliser l'événement spécifique TripUpdateStatus au lieu de TripUpdate
    context.read<TripBloc>().add(
      TripUpdateStatus(
        id: trip.id,
        status: newStatus,
      ),
    );
  }
} 