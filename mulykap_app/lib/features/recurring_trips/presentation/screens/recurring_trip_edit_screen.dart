import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/weekday.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_event.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_state.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';

class RecurringTripEditScreen extends StatefulWidget {
  final RecurringTripModel trip;

  const RecurringTripEditScreen({
    Key? key, 
    required this.trip,
  }) : super(key: key);

  @override
  State<RecurringTripEditScreen> createState() => _RecurringTripEditScreenState();
}

class _RecurringTripEditScreenState extends State<RecurringTripEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _selectedRouteId;
  String? _selectedBusId;
  late List<int> _selectedWeekdays;
  late TimeOfDay _departureTime;
  late TimeOfDay _arrivalTime;
  late double _basePrice;
  late DateTime _validFrom;
  late DateTime _validUntil;
  late bool _isActive;
  
  List<RouteModel> _routes = [];
  List<BusModel> _buses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialiser les valeurs à partir du voyage récurrent existant
    _initializeValues();
    _loadData();
  }

  void _initializeValues() {
    // Récupérer les valeurs du voyage existant
    _selectedRouteId = widget.trip.routeId;
    _selectedBusId = widget.trip.busId;
    _selectedWeekdays = List.from(widget.trip.weekdays);
    _isActive = widget.trip.isActive;
    
    // Convertir la chaîne d'heure au format HH:mm en TimeOfDay
    final departureTimeParts = widget.trip.departureTime.split(':');
    _departureTime = TimeOfDay(
      hour: int.parse(departureTimeParts[0]),
      minute: int.parse(departureTimeParts[1]),
    );
    
    final arrivalTimeParts = widget.trip.arrivalTime.split(':');
    _arrivalTime = TimeOfDay(
      hour: int.parse(arrivalTimeParts[0]),
      minute: int.parse(arrivalTimeParts[1]),
    );
    
    _basePrice = widget.trip.basePrice;
    _validFrom = widget.trip.validFrom;
    _validUntil = widget.trip.validUntil ?? DateTime.now().add(const Duration(days: 365));
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final routeRepository = context.read<RouteRepository>();
      final busRepository = context.read<BusRepository>();

      final routes = await routeRepository.getAllRoutes();
      final buses = await busRepository.getAllBuses();

      setState(() {
        _routes = routes;
        _buses = buses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDeparture) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDeparture ? _departureTime : _arrivalTime,
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureTime = picked;
        } else {
          _arrivalTime = picked;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _validFrom : _validUntil,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Permettre de sélectionner une date dans le passé pour l'édition
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _validFrom = picked;
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }
    
    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un jour de la semaine')),
      );
      return;
    }

    try {
      // Formater les heures au format HH:MM
      final departureTimeStr = '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';
      final arrivalTimeStr = '${_arrivalTime.hour.toString().padLeft(2, '0')}:${_arrivalTime.minute.toString().padLeft(2, '0')}';

      final updatedTrip = widget.trip.copyWith(
        routeId: _selectedRouteId,
        busId: _selectedBusId,
        weekdays: _selectedWeekdays,
        departureTime: departureTimeStr,
        arrivalTime: arrivalTimeStr,
        basePrice: _basePrice,
        isActive: _isActive,
        validFrom: _validFrom,
        validUntil: _validUntil,
      );
      
      // Afficher un message de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour du voyage récurrent en cours...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Envoyer l'événement au bloc
      context.read<RecurringTripBloc>().add(RecurringTripUpdate(updatedTrip));
      
      // Fermer la boîte de dialogue immédiatement
      Navigator.of(context).pop();
      
    } catch (e) {
      print('Error updating recurring trip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le Voyage Récurrent'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sélection de l'itinéraire
                DropdownButtonFormField<String>(
                  value: _selectedRouteId,
                  decoration: const InputDecoration(
                    labelText: 'Itinéraire',
                    border: OutlineInputBorder(),
                  ),
                  items: _routes.map((route) {
                    return DropdownMenuItem(
                      value: route.id,
                      child: Text(route.routeDisplayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRouteId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner un itinéraire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Sélection du bus
                DropdownButtonFormField<String?>(
                  value: _selectedBusId,
                  decoration: const InputDecoration(
                    labelText: 'Bus (optionnel)',
                    border: OutlineInputBorder(),
                    helperText: 'Vous pourrez assigner un bus ultérieurement',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Aucun bus assigné'),
                    ),
                    ..._buses.map((bus) {
                      return DropdownMenuItem<String?>(
                        value: bus.id,
                        child: Text(bus.licensePlate),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBusId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Statut du voyage
                SwitchListTile(
                  title: const Text('Voyage actif'),
                  value: _isActive,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  subtitle: Text(
                    _isActive 
                        ? 'Le voyage est actif et sera affiché dans les recherches'
                        : 'Le voyage est inactif et ne sera pas affiché dans les recherches',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sélection des jours de la semaine
                const Text(
                  'Jours de la semaine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3, 4, 5, 6, 7].map((weekday) {
                    final weekdayName = Weekday.values[weekday - 1].displayName;
                    final isSelected = _selectedWeekdays.contains(weekday);
                    return FilterChip(
                      label: Text(weekdayName),
                      selected: isSelected,
                      onSelected: (_) => _toggleWeekday(weekday),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Horaires
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Heure de départ',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
                        ),
                        onTap: () => _selectTime(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Heure d\'arrivée',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: '${_arrivalTime.hour.toString().padLeft(2, '0')}:${_arrivalTime.minute.toString().padLeft(2, '0')}',
                        ),
                        onTap: () => _selectTime(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Prix de base
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Prix de base',
                    border: OutlineInputBorder(),
                    prefixText: 'FC ',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _basePrice.toString(),
                  onChanged: (value) {
                    setState(() {
                      _basePrice = double.tryParse(value) ?? 0.0;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prix';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dates de validité
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Valide du',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: '${_validFrom.day.toString().padLeft(2, '0')}/${_validFrom.month.toString().padLeft(2, '0')}/${_validFrom.year}',
                        ),
                        onTap: () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Valide jusqu\'au',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: '${_validUntil.day.toString().padLeft(2, '0')}/${_validUntil.month.toString().padLeft(2, '0')}/${_validUntil.year}',
                        ),
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bouton de soumission
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Enregistrer les modifications'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 