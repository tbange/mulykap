import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

class TripListScreen extends StatefulWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  TripStatus? _selectedStatus;
  TabController? _tabController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  
  List<DriverModel> _drivers = [];
  List<BusModel> _buses = [];
  bool _isLoadingDrivers = false;
  bool _isLoadingBuses = false;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Chargement initial des voyages
    context.read<TripBloc>().add(TripLoadAll());
    
    // Chargement des chauffeurs et des bus pour les assignations
    _loadDrivers();
    _loadBuses();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyages'),
        actions: [
          // Bouton de filtre par date
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrer par date',
            onPressed: _selectDateFilter,
          ),
          // Bouton pour ouvrir le menu de filtres
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer par statut',
            onPressed: _showFilterBottomSheet,
          ),
          // Bouton pour rafraîchir la liste
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () => context.read<TripBloc>().add(TripLoadAll()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Aujourd\'hui'),
            Tab(text: 'À venir'),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                context.read<TripBloc>().add(TripResetFilters());
                break;
              case 1:
                context.read<TripBloc>().add(TripFilterByDate(DateTime.now()));
                break;
              case 2:
                final today = DateTime.now();
                context.read<TripBloc>().add(TripFilterByDateRange(
                  startDate: today.add(const Duration(days: 1)), 
                  endDate: today.add(const Duration(days: 10)),
                ));
                break;
            }
          },
        ),
      ),
      body: BlocBuilder<TripBloc, TripState>(
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

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TripBloc>().add(TripLoadAll());
            },
            child: Column(
              children: [
                // Afficher les filtres actifs
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
                        
                        // Filtre de statut
                        if (state.statusFilter != null)
                          Chip(
                            label: Text(state.statusFilter!.displayName),
                            deleteIcon: const Icon(Icons.clear, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedStatus = null;
                              });
                              context.read<TripBloc>().add(
                                    TripFilterByStatus(null),
                                  );
                            },
                          ),
                        
                        const SizedBox(width: 8),
                        
                        // Filtre de date
                        if (state.dateFilter != null)
                          Chip(
                            label: Text(
                              _dateFormat.format(state.dateFilter!),
                            ),
                            deleteIcon: const Icon(Icons.clear, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedDate = null;
                              });
                              context.read<TripBloc>().add(
                                    TripFilterByDate(null),
                                  );
                            },
                          ),
                          
                        const Spacer(),
                        
                        // Bouton pour réinitialiser tous les filtres
                        TextButton.icon(
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Tout effacer'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                              _selectedStatus = null;
                              _tabController?.index = 0;
                            });
                            context.read<TripBloc>().add(TripResetFilters());
                          },
                        ),
                      ],
                    ),
                  ),
                
                // Liste des voyages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: trips.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _buildTripCard(trip);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        },
        tooltip: 'Retour en haut',
        child: const Icon(Icons.arrow_upward),
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

  Future<void> _selectDateFilter() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      
      context.read<TripBloc>().add(TripFilterByDate(pickedDate));
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusFilterChip(
                        TripStatus.planned,
                        'Programmé',
                        Icons.schedule,
                        Colors.orange,
                        setState,
                      ),
                      _buildStatusFilterChip(
                        TripStatus.in_progress,
                        'En cours',
                        Icons.directions_bus,
                        Colors.blue,
                        setState,
                      ),
                      _buildStatusFilterChip(
                        TripStatus.completed,
                        'Terminé',
                        Icons.check_circle,
                        Colors.green,
                        setState,
                      ),
                      _buildStatusFilterChip(
                        TripStatus.cancelled,
                        'Annulé',
                        Icons.cancel,
                        Colors.red,
                        setState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = null;
                          });
                          
                          this.setState(() {
                            _selectedStatus = null;
                          });
                          
                          Navigator.pop(context);
                          
                          context.read<TripBloc>().add(
                            TripFilterByStatus(null),
                          );
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          
                          if (_selectedStatus != null) {
                            context.read<TripBloc>().add(
                              TripFilterByStatus(_selectedStatus),
                                );
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

  Widget _buildStatusFilterChip(
    TripStatus status,
    String label,
    IconData icon,
    Color color,
    StateSetter setState,
  ) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      label: Text(label),
      avatar: Icon(
        icon,
        color: isSelected ? Colors.white : color,
        size: 18,
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
        
        this.setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
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
    // Mettre à jour le statut du voyage
    context.read<TripBloc>().add(
      TripUpdate(
        trip.copyWith(
          status: newStatus,
        ),
      ),
    );
  }
} 