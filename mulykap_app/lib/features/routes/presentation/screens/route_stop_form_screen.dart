import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/common/presentation/widgets/app_loading_indicator.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_stop_repository.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/domain/models/route_stop_model.dart';
import 'package:mulykap_app/features/shared/presentation/widgets/app_error_widget.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:uuid/uuid.dart';

class RouteStopFormScreen extends StatefulWidget {
  final String routeId;
  final String? stopId;

  const RouteStopFormScreen({
    Key? key,
    required this.routeId,
    this.stopId,
  }) : super(key: key);

  @override
  State<RouteStopFormScreen> createState() => _RouteStopFormScreenState();
}

class _RouteStopFormScreenState extends State<RouteStopFormScreen> {
  late RouteStopRepository _routeStopRepository;
  late RouteRepository _routeRepository;
  late CityRepository _cityRepository;

  bool _isLoading = true;
  String? _errorMessage;
  
  RouteModel? _route;
  List<RouteStopModel> _existingStops = [];
  List<CityModel> _cities = [];
  Map<String, CityModel> _citiesMap = {};
  
  // Liste des arrêts à ajouter/modifier
  List<_StopFormData> _stopsData = [];
  
  // Index de l'étape actuelle dans le Stepper
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    
    _routeStopRepository = context.read<RouteStopRepository>();
    _routeRepository = context.read<RouteRepository>();
    _cityRepository = context.read<CityRepository>();
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger l'itinéraire
      final route = await _routeRepository.getRouteById(widget.routeId);
      if (route == null) {
        setState(() {
          _errorMessage = 'Itinéraire non trouvé';
          _isLoading = false;
        });
        return;
      }
      
      // Charger les villes
      final cities = await _cityRepository.getAllCities();
      final Map<String, CityModel> citiesMap = {};
      for (final city in cities) {
        citiesMap[city.id] = city;
      }
      
      // Charger les arrêts existants pour cet itinéraire
      final existingStops = await _routeStopRepository.getStopsForRoute(widget.routeId);
      
      // Si on est en mode édition d'un arrêt
      if (widget.stopId != null) {
        final stopToEdit = existingStops.firstWhere(
          (stop) => stop.id == widget.stopId,
          orElse: () => throw Exception('Arrêt non trouvé'),
        );
        
        // Initialiser avec l'arrêt à modifier
        _stopsData = [
          _StopFormData(
            id: stopToEdit.id,
            cityId: stopToEdit.cityId,
            stopOrder: stopToEdit.stopOrder,
            stopType: stopToEdit.stopType,
            distanceFromPrevious: stopToEdit.distanceFromPrevious,
            durationFromPrevious: stopToEdit.durationFromPrevious,
            waitingTime: stopToEdit.waitingTime,
          ),
        ];
      } else {
        // Mode création - préremplir avec la ville de départ et d'arrivée de l'itinéraire
        final departureCityId = route.departureCityId;
        final arrivalCityId = route.arrivalCityId;
        
        // Si aucun arrêt n'existe encore, créer les arrêts de départ et d'arrivée
        if (existingStops.isEmpty) {
          _stopsData = [
            _StopFormData(
              id: const Uuid().v4(),
              cityId: departureCityId,
              stopOrder: 1,
              stopType: StopType.depart,
              distanceFromPrevious: 0,
              durationFromPrevious: Duration.zero,
              waitingTime: Duration.zero,
            ),
            _StopFormData(
              id: const Uuid().v4(),
              cityId: arrivalCityId,
              stopOrder: 2,
              stopType: StopType.arrivee,
              distanceFromPrevious: route.distanceKm,
              durationFromPrevious: route.estimatedDuration,
              waitingTime: Duration.zero,
            ),
          ];
        } else {
          // Si des arrêts existent déjà, proposer d'ajouter un arrêt intermédiaire
          // Trouver le dernier ordre d'arrêt
          final maxOrder = existingStops.map((s) => s.stopOrder).reduce((a, b) => a > b ? a : b);
          
          // Par défaut, ajouter un arrêt intermédiaire avant la dernière étape
          _stopsData = [
            _StopFormData(
              id: const Uuid().v4(),
              cityId: '',
              stopOrder: maxOrder,
              stopType: StopType.intermediaire,
              distanceFromPrevious: 0,
              durationFromPrevious: Duration.zero,
              waitingTime: Duration.zero,
            ),
          ];
          
          // Réordonner les arrêts existants si nécessaire
          final arrivalStop = existingStops.firstWhere(
            (stop) => stop.stopType == StopType.arrivee,
            orElse: () => existingStops.last,
          );
          
          if (arrivalStop.stopOrder == maxOrder) {
            _stopsData[0] = _stopsData.first.copyWith(stopOrder: maxOrder);
            // On modifiera l'ordre de l'arrêt d'arrivée lors de l'enregistrement
          }
        }
      }
      
      setState(() {
        _route = route;
        _cities = cities;
        _citiesMap = citiesMap;
        _existingStops = existingStops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Enregistrer les arrêts
  Future<void> _saveStops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (widget.stopId != null) {
        // Mise à jour d'un arrêt existant
        final stopData = _stopsData.first;
        final updatedStop = RouteStopModel(
          id: stopData.id,
          routeId: widget.routeId,
          cityId: stopData.cityId,
          stopOrder: stopData.stopOrder,
          stopType: stopData.stopType,
          distanceFromPrevious: stopData.distanceFromPrevious,
          durationFromPrevious: stopData.durationFromPrevious,
          waitingTime: stopData.waitingTime,
        );
        
        await _routeStopRepository.updateStop(updatedStop);
      } else {
        // Création de nouveaux arrêts
        final stopsToCreate = _stopsData.map((stopData) => RouteStopModel(
          id: stopData.id,
          routeId: widget.routeId,
          cityId: stopData.cityId,
          stopOrder: stopData.stopOrder,
          stopType: stopData.stopType,
          distanceFromPrevious: stopData.distanceFromPrevious,
          durationFromPrevious: stopData.durationFromPrevious,
          waitingTime: stopData.waitingTime,
        )).toList();
        
        // Si des arrêts existants doivent être mis à jour (comme l'ordre)
        final existingStopsToUpdate = <RouteStopModel>[];
        
        // Si on ajoute un arrêt intermédiaire, il faut mettre à jour l'ordre
        // des arrêts suivants
        if (_existingStops.isNotEmpty && stopsToCreate.length == 1) {
          final newStopOrder = stopsToCreate.first.stopOrder;
          
          for (final stop in _existingStops) {
            if (stop.stopOrder >= newStopOrder) {
              existingStopsToUpdate.add(stop.copyWith(
                stopOrder: stop.stopOrder + 1,
              ));
            }
          }
        }
        
        // Mettre à jour les arrêts existants d'abord
        for (final stop in existingStopsToUpdate) {
          await _routeStopRepository.updateStop(stop);
        }
        
        // Puis créer les nouveaux arrêts
        await _routeStopRepository.createMultipleStops(stopsToCreate);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Retourner success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Annuler et retourner à l'écran précédent
  void _cancel() {
    Navigator.of(context).pop();
  }

  // Mettre à jour les données d'un arrêt
  void _updateStopData(int index, _StopFormData newData) {
    setState(() {
      _stopsData[index] = newData;
    });
  }

  // Ajouter un nouvel arrêt (pour le cas de plusieurs arrêts)
  void _addStopData() {
    setState(() {
      final newStopOrder = _stopsData.isNotEmpty 
          ? _stopsData.last.stopOrder + 1 
          : 1;
      
      _stopsData.add(_StopFormData(
        id: const Uuid().v4(),
        cityId: '',
        stopOrder: newStopOrder,
        stopType: StopType.intermediaire,
        distanceFromPrevious: 0,
        durationFromPrevious: Duration.zero,
        waitingTime: Duration.zero,
      ));
    });
  }

  // Supprimer un arrêt de la liste temporaire
  void _removeStopData(int index) {
    setState(() {
      _stopsData.removeAt(index);
      
      // Réordonner les arrêts restants
      for (int i = 0; i < _stopsData.length; i++) {
        _stopsData[i] = _stopsData[i].copyWith(stopOrder: i + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.stopId != null ? l10n.editStop : l10n.addStop)),
        body: const AppLoadingIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.stopId != null ? l10n.editStop : l10n.addStop)),
        body: AppErrorWidget(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stopId != null 
          ? l10n.editStop 
          : _existingStops.isEmpty 
              ? "Configuration des arrêts" 
              : l10n.addStop
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < _stopsData.length - 1) {
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  _saveStops();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep--;
                  });
                } else {
                  _cancel();
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep < _stopsData.length - 1
                            ? "Suivant"
                            : "Enregistrer"),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(_currentStep > 0 ? "Précédent" : l10n.cancel),
                      ),
                    ],
                  ),
                );
              },
              steps: _buildSteps(context),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.stopId == null && _existingStops.isEmpty
          ? FloatingActionButton(
              onPressed: _addStopData,
              tooltip: "Ajouter un arrêt intermédiaire",
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  List<Step> _buildSteps(BuildContext context) {
    return List.generate(_stopsData.length, (index) {
      final stopData = _stopsData[index];
      final cityName = stopData.cityId.isNotEmpty
          ? _citiesMap[stopData.cityId]?.name ?? 'Ville inconnue'
          : 'Sélectionner une ville';
          
      return Step(
        title: Text(_getStepTitle(index, stopData)),
        subtitle: Text(cityName),
        content: _StopForm(
          stopData: stopData,
          cities: _cities,
          onChanged: (newData) => _updateStopData(index, newData),
          showRemoveButton: _stopsData.length > 2 && index > 0 && index < _stopsData.length - 1,
          onRemove: () => _removeStopData(index),
        ),
        isActive: _currentStep == index,
        state: _getStepState(index),
      );
    });
  }

  String _getStepTitle(int index, _StopFormData stopData) {
    if (stopData.stopType == StopType.depart) {
      return "Point de départ";
    } else if (stopData.stopType == StopType.arrivee) {
      return "Point d'arrivée";
    } else {
      return "Arrêt intermédiaire ${stopData.stopOrder}";
    }
  }

  StepState _getStepState(int index) {
    if (index < _currentStep) {
      return StepState.complete;
    } else if (index == _currentStep) {
      return StepState.editing;
    } else {
      return StepState.indexed;
    }
  }
}

// Classe pour stocker les données du formulaire d'un arrêt
class _StopFormData {
  final String id;
  final String cityId;
  final int stopOrder;
  final StopType stopType;
  final double? distanceFromPrevious;
  final Duration? durationFromPrevious;
  final Duration? waitingTime;

  _StopFormData({
    required this.id,
    required this.cityId,
    required this.stopOrder,
    required this.stopType,
    this.distanceFromPrevious,
    this.durationFromPrevious,
    this.waitingTime,
  });

  _StopFormData copyWith({
    String? id,
    String? cityId,
    int? stopOrder,
    StopType? stopType,
    double? distanceFromPrevious,
    Duration? durationFromPrevious,
    Duration? waitingTime,
  }) {
    return _StopFormData(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      stopOrder: stopOrder ?? this.stopOrder,
      stopType: stopType ?? this.stopType,
      distanceFromPrevious: distanceFromPrevious ?? this.distanceFromPrevious,
      durationFromPrevious: durationFromPrevious ?? this.durationFromPrevious,
      waitingTime: waitingTime ?? this.waitingTime,
    );
  }
}

// Widget de formulaire pour un arrêt
class _StopForm extends StatefulWidget {
  final _StopFormData stopData;
  final List<CityModel> cities;
  final Function(_StopFormData) onChanged;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const _StopForm({
    Key? key,
    required this.stopData,
    required this.cities,
    required this.onChanged,
    this.showRemoveButton = false,
    this.onRemove,
  }) : super(key: key);

  @override
  State<_StopForm> createState() => _StopFormState();
}

class _StopFormState extends State<_StopForm> {
  late String _cityId;
  late double? _distanceFromPrevious;
  late int _durationHours;
  late int _durationMinutes;
  late int _waitingTimeMinutes;

  @override
  void initState() {
    super.initState();
    
    _cityId = widget.stopData.cityId;
    _distanceFromPrevious = widget.stopData.distanceFromPrevious;
    
    final duration = widget.stopData.durationFromPrevious ?? Duration.zero;
    _durationHours = duration.inHours;
    _durationMinutes = duration.inMinutes.remainder(60);
    
    final waitingTime = widget.stopData.waitingTime ?? Duration.zero;
    _waitingTimeMinutes = waitingTime.inMinutes;
  }

  void _updateStopData() {
    final newData = widget.stopData.copyWith(
      cityId: _cityId,
      distanceFromPrevious: _distanceFromPrevious,
      durationFromPrevious: Duration(
        hours: _durationHours,
        minutes: _durationMinutes,
      ),
      waitingTime: Duration(minutes: _waitingTimeMinutes),
    );
    
    widget.onChanged(newData);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélection de la ville
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: l10n.city,
            border: const OutlineInputBorder(),
          ),
          value: _cityId.isNotEmpty ? _cityId : null,
          hint: Text("Sélectionner une ville"),
          items: widget.cities.map((city) {
            return DropdownMenuItem<String>(
              value: city.id,
              child: Text(city.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _cityId = value;
              });
              _updateStopData();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Ce champ est obligatoire";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Type d'arrêt (départ, intermédiaire, arrivée)
        if (widget.stopData.stopType == StopType.intermediaire)
          Text(
            "Type d'arrêt: ${widget.stopData.stopType.displayName}",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        
        const SizedBox(height: 16),
        
        // Distance depuis l'arrêt précédent
        if (widget.stopData.stopType != StopType.depart)
          TextFormField(
            decoration: InputDecoration(
              labelText: "Distance depuis l'arrêt précédent",
              suffixText: 'km',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            initialValue: _distanceFromPrevious?.toString() ?? '',
            onChanged: (value) {
              setState(() {
                _distanceFromPrevious = double.tryParse(value) ?? 0;
              });
              _updateStopData();
            },
          ),
        
        if (widget.stopData.stopType != StopType.depart)
          const SizedBox(height: 16),
        
        // Durée depuis l'arrêt précédent
        if (widget.stopData.stopType != StopType.depart)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Heures",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  initialValue: _durationHours.toString(),
                  onChanged: (value) {
                    setState(() {
                      _durationHours = int.tryParse(value) ?? 0;
                    });
                    _updateStopData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Minutes",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  initialValue: _durationMinutes.toString(),
                  onChanged: (value) {
                    setState(() {
                      _durationMinutes = int.tryParse(value) ?? 0;
                    });
                    _updateStopData();
                  },
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 16),
        
        // Temps d'attente à cet arrêt
        TextFormField(
          decoration: InputDecoration(
            labelText: "Temps d'attente (minutes)",
            suffixText: 'min',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          initialValue: _waitingTimeMinutes.toString(),
          onChanged: (value) {
            setState(() {
              _waitingTimeMinutes = int.tryParse(value) ?? 0;
            });
            _updateStopData();
          },
        ),
        
        if (widget.showRemoveButton)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: Text("Supprimer cet arrêt"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: widget.onRemove,
            ),
          ),
      ],
    );
  }
}
