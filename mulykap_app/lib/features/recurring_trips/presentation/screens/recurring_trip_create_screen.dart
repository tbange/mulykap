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

class RecurringTripCreateScreen extends StatefulWidget {
  const RecurringTripCreateScreen({Key? key}) : super(key: key);

  @override
  State<RecurringTripCreateScreen> createState() => _RecurringTripCreateScreenState();
}

class _RecurringTripCreateScreenState extends State<RecurringTripCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedRouteId;
  String? _selectedBusId;
  final List<Weekday> _selectedWeekdays = [];
  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 9, minute: 0);
  double _basePrice = 0.0;
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 365));
  
  List<RouteModel> _routes = [];
  List<BusModel> _buses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      firstDate: DateTime.now(),
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

  void _toggleWeekday(Weekday weekday) {
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
    
    if (_selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un itinéraire')),
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

      final trip = RecurringTripModel(
        id: '',  // Sera généré par le repository
        routeId: _selectedRouteId!,
        busId: _selectedBusId ?? '',
        weekdays: _selectedWeekdays.map((w) => w.index + 1).toList(),
        departureTime: departureTimeStr,
        arrivalTime: arrivalTimeStr,
        basePrice: _basePrice,
        isActive: true,
        validFrom: _validFrom,
        validUntil: _validUntil,
      );
      
      // Afficher un message de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Création du voyage récurrent en cours...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Envoyer l'événement au bloc
      context.read<RecurringTripBloc>().add(RecurringTripCreate(trip));
      
      // Fermer la boîte de dialogue immédiatement
      Navigator.of(context).pop();
      
    } catch (e) {
      print('Error creating recurring trip: $e');
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
        title: const Text('Nouveau Voyage Récurrent'),
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
                    setState(() {
                      _selectedRouteId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner un itinéraire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Sélection du bus
                DropdownButtonFormField<String>(
                  value: _selectedBusId,
                  decoration: const InputDecoration(
                    labelText: 'Bus',
                    border: OutlineInputBorder(),
                  ),
                  items: _buses.map((bus) {
                    return DropdownMenuItem(
                      value: bus.id,
                      child: Text(bus.licensePlate),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBusId = value;
                    });
                  },
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
                  children: Weekday.values.map((weekday) {
                    final isSelected = _selectedWeekdays.contains(weekday);
                    return FilterChip(
                      label: Text(weekday.displayName),
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
                          text: '${_departureTime.hour}:${_departureTime.minute.toString().padLeft(2, '0')}',
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
                          text: '${_arrivalTime.hour}:${_arrivalTime.minute.toString().padLeft(2, '0')}',
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
                    prefixText: '\$',
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
                          text: '${_validFrom.day}/${_validFrom.month}/${_validFrom.year}',
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
                          text: '${_validUntil.day}/${_validUntil.month}/${_validUntil.year}',
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
                  child: const Text('Créer le voyage récurrent'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 