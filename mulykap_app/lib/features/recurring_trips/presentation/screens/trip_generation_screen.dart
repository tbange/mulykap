import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mulykap_app/core/presentation/widgets/error_message.dart';
import 'package:mulykap_app/core/presentation/widgets/loading_spinner.dart';
import 'package:mulykap_app/features/drivers/data/repositories/driver_repository.dart';
import 'package:mulykap_app/features/drivers/domain/models/driver_model.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_event.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_state.dart';
import 'package:mulykap_app/features/recurring_trips/data/repositories/recurring_trip_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripGenerationScreen extends StatefulWidget {
  final String? recurringTripId; // Si null, génère pour tous les voyages récurrents

  const TripGenerationScreen({Key? key, this.recurringTripId}) : super(key: key);
  
  // Méthode statique pour créer TripGenerationScreen avec son BlocProvider
  static Route<dynamic> route(BuildContext context, {String? recurringTripId}) {
    return MaterialPageRoute(
      builder: (context) => BlocProvider<RecurringTripBloc>(
        create: (context) => RecurringTripBloc(
          repository: RepositoryProvider.of<RecurringTripRepository>(context),
        ),
        child: TripGenerationScreen(recurringTripId: recurringTripId),
      ),
    );
  }

  @override
  State<TripGenerationScreen> createState() => _TripGenerationScreenState();
}

class _TripGenerationScreenState extends State<TripGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _startDate = DateTime.now(); // Valeur par défaut, sera mise à jour avec valid_from
  DateTime _endDate = DateTime.now().add(const Duration(days: 30)); // Valeur par défaut, sera mise à jour avec valid_until
  String? _selectedDriverId;
  bool _isGeneratingForAll = false;
  List<DriverModel> _drivers = [];
  bool _isLoadingDrivers = false;
  RecurringTripModel? _selectedTrip;
  bool _isLoadingTrip = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser les variables
    _isGeneratingForAll = widget.recurringTripId == null;
    
    // Charger les chauffeurs pour le sélecteur
    _loadDrivers();
    
    // Si un ID de voyage récurrent est fourni, charger les détails
    if (widget.recurringTripId != null) {
      _loadRecurringTripDetails();
    }
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
    });
    
    try {
      final DriverRepository driverRepository = DriverRepository(
        supabaseClient: Supabase.instance.client,
      );
      
      final drivers = await driverRepository.getAllDrivers();
      
      setState(() {
        _drivers = drivers;
        _isLoadingDrivers = false;
      });
    } catch (e) {
      // Gérer l'erreur de chargement des chauffeurs
      setState(() {
        _isLoadingDrivers = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des chauffeurs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecurringTripDetails() async {
    setState(() {
      _isLoadingTrip = true;
    });
    
    try {
      if (!mounted) return;
      
      final RecurringTripBloc bloc = context.read<RecurringTripBloc>();
      final currentState = bloc.state;
      
      // Chercher le voyage récurrent dans la liste déjà chargée
      if (currentState.trips.isNotEmpty) {
        final trip = currentState.trips.firstWhere(
          (trip) => trip.id == widget.recurringTripId,
          orElse: () => throw Exception('Voyage récurrent non trouvé'),
        );
        
        setState(() {
          _selectedTrip = trip;
          
          // Initialiser les dates de génération avec les dates de validité du voyage récurrent
          _startDate = trip.validFrom;
          _endDate = trip.validUntil ?? _startDate.add(const Duration(days: 365)); // Si pas de date de fin, utiliser 1 an
          _isLoadingTrip = false;
        });
      } else {
        // Si la liste n'est pas chargée, recharger tous les voyages
        bloc.add(RecurringTripLoadAll());
        
        // Écouter l'état du bloc pour obtenir les voyages une fois chargés
        bloc.stream.listen((state) {
          if (!mounted) return;
          // Vérifier que les données sont chargées (pas en chargement, pas d'erreur et liste non vide)
          if (!state.isLoading && state.trips.isNotEmpty && !state.isError) {
            try {
              final trip = state.trips.firstWhere(
                (trip) => trip.id == widget.recurringTripId,
                orElse: () => throw Exception('Voyage récurrent non trouvé'),
              );
              
              setState(() {
                _selectedTrip = trip;
                
                // Initialiser les dates de génération avec les dates de validité du voyage récurrent
                _startDate = trip.validFrom;
                _endDate = trip.validUntil ?? _startDate.add(const Duration(days: 365)); // Si pas de date de fin, utiliser 1 an
                _isLoadingTrip = false;
              });
            } catch (e) {
              setState(() {
                _isLoadingTrip = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingTrip = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des détails: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateTrips() {
    if (_formKey.currentState!.validate()) {
      final RecurringTripBloc bloc = context.read<RecurringTripBloc>();
      
      if (_isGeneratingForAll) {
        // Générer pour tous les voyages récurrents actifs
        bloc.add(RecurringTripGenerateAllTrips(
          startDate: _startDate,
          endDate: _endDate,
        ));
      } else if (_selectedTrip != null) { // Vérifier que le voyage est bien chargé
        // Générer pour un voyage récurrent spécifique
        bloc.add(RecurringTripGenerateTrips(
          recurringTripId: widget.recurringTripId!,
          startDate: _startDate,
          endDate: _endDate,
          driverId: _selectedDriverId,
        ));
      } else {
        // Afficher un message d'erreur si le voyage n'est pas chargé
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Détails du voyage non chargés. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGeneratingForAll 
            ? 'Générer tous les voyages' 
            : 'Générer voyages ${_selectedTrip?.routeName ?? ""}'),
      ),
      body: BlocConsumer<RecurringTripBloc, RecurringTripState>(
        listener: (context, state) {
          // Gérer les différents états de la génération
          if (state.isGenerationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${state.generatedTripsCount} voyages ont été générés avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.isGenerationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.generationError}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isGenerating) {
            return const LoadingSpinner(message: 'Génération des voyages en cours...');
          }
          
          if (_isLoadingTrip && !_isGeneratingForAll) {
            return const LoadingSpinner(message: 'Chargement des détails du voyage...');
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Afficher les détails du voyage récurrent (si spécifique)
                  if (!_isGeneratingForAll && _selectedTrip != null)
                    _buildTripDetailsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Sélection de la période
                  _buildDateRangeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Sélection du chauffeur (uniquement pour un voyage spécifique)
                  if (!_isGeneratingForAll)
                    _buildDriverSelection(),
                  
                  const SizedBox(height: 32),
                  
                  // Bouton de génération
                  ElevatedButton.icon(
                    onPressed: state.isGenerating ? null : _generateTrips,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_isGeneratingForAll 
                        ? 'Générer pour tous les voyages récurrents actifs' 
                        : 'Générer pour ce voyage récurrent'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                  
                  // Information sur le nombre de voyages générés
                  if (state.isGenerationSuccess)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Génération réussie',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '${state.generatedTripsCount} voyages ont été générés',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildTripDetailsCard() {
    final trip = _selectedTrip!;
    
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    trip.routeName ?? 'Itinéraire inconnu',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow(Icons.access_time, 'Départ', trip.departureTime),
            _buildDetailRow(Icons.access_time, 'Arrivée', trip.arrivalTime),
            _buildDetailRow(Icons.calendar_today, 'Jours', _getWeekdaysText(trip.weekdays)),
            _buildDetailRow(Icons.attach_money, 'Prix de base', '${trip.basePrice.toInt()} FCFA'),
            if (trip.busId != null)
              _buildDetailRow(Icons.directions_bus, 'Bus', trip.busPlate ?? 'Non spécifié'),
            _buildDetailRow(
              Icons.date_range, 
              'Validité', 
              '${DateFormat('dd/MM/yyyy').format(trip.validFrom)} - ${trip.validUntil != null ? DateFormat('dd/MM/yyyy').format(trip.validUntil!) : 'Indéterminée'}'
            ),
            _buildDetailRow(
              Icons.check_circle_outline, 
              'Statut', 
              trip.isActive ? 'Actif' : 'Inactif',
              color: trip.isActive ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14.0,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période de génération',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Afficher la période de validité du voyage récurrent
        if (_selectedTrip != null) 
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              'Les voyages seront générés pour la période de validité: ${DateFormat('dd/MM/yyyy').format(_selectedTrip!.validFrom)} → ' +
              (_selectedTrip!.validUntil != null ? DateFormat('dd/MM/yyyy').format(_selectedTrip!.validUntil!) : 'indéfinie'),
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blue,
                fontSize: 14.0,
              ),
            ),
          ),
        
        // Afficher la durée de la période
        const SizedBox(height: 8.0),
        if (_selectedTrip != null && _selectedTrip!.validUntil != null)
          Text(
            'Durée: ${_selectedTrip!.validUntil!.difference(_selectedTrip!.validFrom).inDays + 1} jours',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildDriverSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chauffeur (optionnel)',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Sélectionner un chauffeur',
            border: OutlineInputBorder(),
            hintText: 'Choisir un chauffeur pour tous les voyages générés',
          ),
          value: _selectedDriverId,
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Aucun chauffeur (à définir plus tard)'),
            ),
            if (_isLoadingDrivers)
              const DropdownMenuItem<String>(
                value: 'loading',
                enabled: false,
                child: Text('Chargement des chauffeurs...'),
              )
            else
              ..._drivers.map((driver) {
                return DropdownMenuItem<String>(
                  value: driver.id,
                  child: Text('${driver.firstName} ${driver.lastName}'),
                );
              }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDriverId = value;
            });
          },
        ),
      ],
    );
  }

  String _getWeekdaysText(List<int> weekdays) {
    final List<String> weekdayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    if (weekdays.length == 7) {
      return 'Tous les jours';
    } else if (weekdays.isEmpty) {
      return 'Aucun jour';
    } else {
      return weekdays
        .map((day) => weekdayNames[day - 1])
        .join(', ');
    }
  }
} 