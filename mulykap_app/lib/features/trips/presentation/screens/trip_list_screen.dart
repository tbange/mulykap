import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mulykap_app/core/presentation/widgets/error_message.dart';
import 'package:mulykap_app/core/presentation/widgets/loading_spinner.dart';
import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_bloc.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_event.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_state.dart';
import 'package:mulykap_app/features/trips/presentation/widgets/trip_item.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  DateTime? _selectedDate;
  TripStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Chargement initial des voyages
    context.read<TripBloc>().add(TripLoadAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyages'),
        actions: [
          // Bouton pour ouvrir le menu de filtres
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
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
                                    TripFilterByStatus(status: null),
                                  );
                            },
                          ),
                        
                        const SizedBox(width: 8),
                        
                        // Filtre de date
                        if (state.dateFilter != null)
                          Chip(
                            label: Text(
                              DateFormat('dd/MM/yyyy').format(state.dateFilter!),
                            ),
                            deleteIcon: const Icon(Icons.clear, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedDate = null;
                              });
                              context.read<TripBloc>().add(
                                    TripFilterByDate(date: null),
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
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return TripItem(
                        trip: trip,
                        onTap: () => _navigateToTripDetail(trip),
                        onEdit: () => _editTrip(trip),
                        onDelete: () => _confirmDeleteTrip(trip),
                        onStatusChange: () => _showChangeStatusDialog(trip),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTrip,
        tooltip: 'Ajouter un voyage',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Afficher la boîte de dialogue pour filtrer les voyages
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    'Filtrer les voyages',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtre par statut
                  const Text('Statut:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TripStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return FilterChip(
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? status : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filtre par date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date:'),
                      if (_selectedDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          child: const Text('Effacer'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate == null
                                ? 'Sélectionner une date'
                                : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _selectedStatus = null;
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Appliquer les filtres
                          if (_selectedStatus != null) {
                            context.read<TripBloc>().add(
                                  TripFilterByStatus(status: _selectedStatus),
                                );
                          }
                          if (_selectedDate != null) {
                            context.read<TripBloc>().add(
                                  TripFilterByDate(date: _selectedDate),
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

  // Navigation vers l'écran de détail d'un voyage
  void _navigateToTripDetail(TripModel trip) {
    // TODO: Implémenter la navigation vers l'écran de détail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Afficher les détails du voyage: ${trip.id}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Modifier un voyage existant
  void _editTrip(TripModel trip) {
    // TODO: Implémenter la modification d'un voyage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modifier le voyage: ${trip.id}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Créer un nouveau voyage
  void _createNewTrip() {
    // TODO: Implémenter la création d'un voyage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Créer un nouveau voyage'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Confirmation de suppression d'un voyage
  void _confirmDeleteTrip(TripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce voyage?'),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer ce voyage?'
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
              context.read<TripBloc>().add(TripDelete(id: trip.id));
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // Boîte de dialogue pour changer le statut d'un voyage
  void _showChangeStatusDialog(TripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TripStatus.values.map((status) {
            return RadioListTile<TripStatus>(
              title: Text(status.displayName),
              value: status,
              groupValue: trip.status,
              onChanged: (newStatus) {
                Navigator.pop(context);
                if (newStatus != null && newStatus != trip.status) {
                  context.read<TripBloc>().add(
                        TripUpdateStatus(
                          id: trip.id,
                          status: newStatus,
                        ),
                      );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
} 