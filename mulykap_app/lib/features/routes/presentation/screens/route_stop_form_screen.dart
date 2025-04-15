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
  
  // État du processus d'ajout d'arrêt
  bool _isAddingStop = false;
  bool _finalStepReached = false;
  
  // Pour stockage temporaire des données du nouvel arrêt
  _StopFormData? _currentStopData;

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
        // Mode création - Nouveau comportement dynamique
        // On commence seulement avec le point de départ
        if (existingStops.isEmpty) {
          _stopsData = [
            _StopFormData(
              id: const Uuid().v4(),
              cityId: route.departureCityId,
              stopOrder: 1,
              stopType: StopType.depart,
              distanceFromPrevious: 0,
              durationFromPrevious: Duration.zero,
              waitingTime: Duration.zero,
            ),
          ];
          
          // Initialiser le formulaire pour le second arrêt (premier arrêt intermédiaire)
          _currentStopData = _StopFormData(
            id: const Uuid().v4(),
            cityId: '', // À sélectionner par l'utilisateur
            stopOrder: 2,
            stopType: StopType.intermediaire,
            distanceFromPrevious: 0, // À définir par l'utilisateur
            durationFromPrevious: Duration.zero, // À définir par l'utilisateur
            waitingTime: const Duration(minutes: 10), // Temps d'arrêt par défaut
          );
          
          _isAddingStop = true;
        } else {
          // Si des arrêts existent déjà mais qu'on veut en ajouter un nouveau
          // Trier les arrêts existants
          final sortedStops = List<RouteStopModel>.from(existingStops)
            ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
          
          // Vérifier si tous les arrêts sont déjà définis
          bool hasArrivalStop = sortedStops.any((stop) => stop.stopType == StopType.arrivee);
          
          if (hasArrivalStop) {
            // Si l'itinéraire est déjà complet, on prépare pour insertion
            int insertIndex = 1; // Par défaut, après le départ
            if (sortedStops.length > 2) {
              // Trouver le plus grand écart entre deux arrêts
              double maxGap = 0;
              for (int i = 0; i < sortedStops.length - 1; i++) {
                final nextStop = sortedStops[i + 1];
                
                if (nextStop.distanceFromPrevious == null) continue;
                
                if (nextStop.distanceFromPrevious! > maxGap) {
                  maxGap = nextStop.distanceFromPrevious!;
                  insertIndex = i + 1;
                }
              }
            }
            
            // Charger les arrêts existants pour les afficher
            _stopsData = sortedStops.map((stop) => _StopFormData(
              id: stop.id,
              cityId: stop.cityId,
              stopOrder: stop.stopOrder,
              stopType: stop.stopType,
              distanceFromPrevious: stop.distanceFromPrevious,
              durationFromPrevious: stop.durationFromPrevious,
              waitingTime: stop.waitingTime,
            )).toList();
            
            // Créer un nouvel arrêt intermédiaire à insérer avant l'arrivée
            int arrivalStopIndex = _stopsData.indexWhere((s) => s.stopType == StopType.arrivee);
            if (arrivalStopIndex > 0) {
              _currentStopData = _StopFormData(
                id: const Uuid().v4(),
                cityId: '', // À sélectionner
                stopOrder: arrivalStopIndex,
                stopType: StopType.intermediaire,
                distanceFromPrevious: 0,
                durationFromPrevious: Duration.zero,
                waitingTime: const Duration(minutes: 10),
              );
              
              _isAddingStop = true;
            }
          } else {
            // S'il n'y a pas encore d'arrêt d'arrivée, on continue le processus
            // Chargement des arrêts existants
            _stopsData = sortedStops.map((stop) => _StopFormData(
              id: stop.id,
              cityId: stop.cityId,
              stopOrder: stop.stopOrder,
              stopType: stop.stopType,
              distanceFromPrevious: stop.distanceFromPrevious,
              durationFromPrevious: stop.durationFromPrevious,
              waitingTime: stop.waitingTime,
            )).toList();
            
            // Nouveau step: arrêt intermédiaire ou d'arrivée selon le contexte
            int nextOrder = _stopsData.length + 1;
            
            // Décider si c'est l'arrêt final (arrivée)
            bool isLastStop = nextOrder >= 3; // Au minimum 3 arrêts (départ, intermédiaire, arrivée)
            
            _currentStopData = _StopFormData(
              id: const Uuid().v4(),
              cityId: isLastStop ? route.arrivalCityId : '',
              stopOrder: nextOrder,
              stopType: isLastStop ? StopType.arrivee : StopType.intermediaire,
              distanceFromPrevious: 0, // À définir
              durationFromPrevious: Duration.zero, // À définir
              waitingTime: isLastStop ? Duration.zero : const Duration(minutes: 10),
            );
            
            _isAddingStop = true;
            _finalStepReached = isLastStop;
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

  // Nouvelle méthode pour trouver les villes intermédiaires potentielles
  List<CityModel> _findPotentialIntermediateCities(
    List<CityModel> allCities, 
    CityModel departureCity, 
    CityModel arrivalCity
  ) {
    List<CityModel> result = [];
    
    // Exemple concret: pour l'itinéraire Lubumbashi -> Kolwezi
    if ((departureCity.name == 'Lubumbashi' && arrivalCity.name == 'Kolwezi') ||
        (departureCity.name == 'Kolwezi' && arrivalCity.name == 'Lubumbashi')) {
      // Ajouter Likasi et Fungurume dans le bon ordre
      final likasi = allCities.firstWhere(
        (city) => city.name == 'Likasi',
        orElse: () => CityModel(
          id: '',
          name: 'Likasi',
          code: 'LIK',
          province: 'Haut-Katanga',
          country: 'RDC',
          isMain: true
        )
      );
      
      final fungurume = allCities.firstWhere(
        (city) => city.name == 'Fungurume',
        orElse: () => CityModel(
          id: '',
          name: 'Fungurume',
          code: 'FUN',
          province: 'Lualaba', 
          country: 'RDC',
          isMain: false
        )
      );
      
      if (departureCity.name == 'Lubumbashi') {
        if (likasi.id.isNotEmpty) result.add(likasi);
        if (fungurume.id.isNotEmpty) result.add(fungurume);
      } else {
        if (fungurume.id.isNotEmpty) result.add(fungurume);
        if (likasi.id.isNotEmpty) result.add(likasi);
      }
      
      return result;
    }
    
    // Méthode générale: trouver les villes principales entre le départ et l'arrivée
    // Cette logique simplifiée sélectionne les villes principales qui pourraient être des arrêts intermédiaires
    final potentialIntermediateCities = allCities.where((city) => 
      city.id != departureCity.id && 
      city.id != arrivalCity.id &&
      city.isMain == true
    ).toList();
    
    // Trier en fonction de la proximité géographique (simplifiée)
    // Pour un vrai système, une logique plus complexe de géolocalisation serait nécessaire
    return potentialIntermediateCities.take(3).toList(); // Limiter à 3 villes intermédiaires max
  }

  // Enregistrer toutes les étapes
  @override
  Future<void> _saveStops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Si on est en train d'ajouter un arrêt, l'ajouter d'abord à la liste
      if (_isAddingStop && _currentStopData != null) {
        if (_currentStopData!.cityId.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Veuillez sélectionner une ville pour tous les arrêts")),
          );
          return;
        }
        
        _stopsData.add(_currentStopData!);
      }
      
      // Trier les arrêts par ordre et réassigner les numéros d'ordre de manière séquentielle
      _stopsData.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
      for (int i = 0; i < _stopsData.length; i++) {
        _stopsData[i] = _stopsData[i].copyWith(stopOrder: i + 1);
      }
      
      // Dans le cas de mise à jour d'un arrêt
      if (widget.stopId != null) {
        final stopData = _stopsData.firstWhere((s) => s.id == widget.stopId);
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
        // Pour la création/configuration initiale d'arrêts
        
        // Supprimer d'abord tous les arrêts existants pour éviter les conflits
        if (_existingStops.isNotEmpty) {
          await _routeStopRepository.deleteAllStopsForRoute(widget.routeId);
        }
        
        // Vérifier l'unicité des stop_order pour un dernier contrôle
        final stopOrders = _stopsData.map((s) => s.stopOrder).toList();
        final uniqueStopOrders = stopOrders.toSet().toList();
        
        if (stopOrders.length != uniqueStopOrders.length) {
          throw Exception("Il y a des numéros d'ordre en double. Veuillez réessayer.");
        }
        
        // Créer les nouveaux arrêts
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
        
        // Créer tous les arrêts en une seule opération
        await _routeStopRepository.createMultipleStops(stopsToCreate);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
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
          : "Configuration des arrêts"
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isAddingStop 
                ? _buildAddStopForm(context) 
                : _buildStepperView(context),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour construire le Stepper des arrêts existants
  Widget _buildStepperView(BuildContext context) {
    return Column(
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
                // Au dernier pas, permettre d'ajouter un nouvel arrêt ou terminer
                if (hasArrivalStop()) {
                  _saveStops();
                } else {
                  setState(() {
                    _isAddingStop = true;
                  });
                }
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
            onStepTapped: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            controlsBuilder: (context, details) {
              bool isLastStep = _currentStep >= _stopsData.length - 1;
              bool canAddIntermediateStop = _stopsData.isNotEmpty;
              
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(isLastStep && hasArrivalStop()
                          ? "Enregistrer"
                          : "Suivant"),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(_currentStep > 0 ? "Précédent" : "Annuler"),
                    ),
                  ],
                ),
              );
            },
            steps: _buildSteps(context),
          ),
        ),
        if (_stopsData.isNotEmpty) 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text("Ajouter un arrêt intermédiaire"),
                  onPressed: () {
                    _showInsertStopDialog();
                  },
                ),
                ElevatedButton(
                  onPressed: _saveStops,
                  child: const Text("Enregistrer"),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Ajouter cette méthode pour vérifier si on a déjà un arrêt d'arrivée
  bool hasArrivalStop() {
    return _stopsData.any((stop) => stop.stopType == StopType.arrivee) || 
           _existingStops.any((stop) => stop.stopType == StopType.arrivee);
  }

  // Ajouter cette méthode pour montrer un dialogue permettant d'insérer un arrêt à une position spécifique
  void _showInsertStopDialog() {
    // Identifier la position actuelle dans le Stepper
    int insertAfterIndex = _currentStep;
    
    // Déterminer la position optimale pour insertion
    // Si on est sur le dernier arrêt et que c'est l'arrivée, insérer avant
    if (insertAfterIndex >= _stopsData.length - 1 && 
        _stopsData.isNotEmpty && 
        _stopsData.last.stopType == StopType.arrivee) {
      insertAfterIndex = _stopsData.length - 2;
    }
    
    // S'assurer que l'index est valide
    insertAfterIndex = insertAfterIndex.clamp(0, _stopsData.length - 1);
    
    // Déterminer l'ordre du nouvel arrêt
    int newStopOrder = _stopsData[insertAfterIndex].stopOrder + 1;
    
    // Initialiser le nouvel arrêt intermédiaire
    _currentStopData = _StopFormData(
      id: const Uuid().v4(),
      cityId: '',
      stopOrder: newStopOrder,
      stopType: StopType.intermediaire,
      distanceFromPrevious: 0,
      durationFromPrevious: Duration.zero,
      waitingTime: const Duration(minutes: 10),
    );
    
    setState(() {
      _isAddingStop = true;
    });
  }

  // Nouvelle version qui gère mieux l'insertion d'arrêts
  Widget _buildAddStopForm(BuildContext context) {
    final stopData = _currentStopData!;
    final stopType = stopData.stopType;
    final isFinalStep = stopType == StopType.arrivee;
    
    String title;
    switch (stopType) {
      case StopType.depart:
        title = "Point de départ";
        break;
      case StopType.arrivee:
        title = "Point d'arrivée";
        break;
      default:
        title = "Arrêt intermédiaire";
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  _StopForm(
                    stopData: stopData,
                    cities: _cities.where((city) => 
                      // Filtrer pour ne pas proposer les villes déjà utilisées comme arrêts
                      !_stopsData.any((stop) => stop.cityId == city.id) || 
                      // Sauf si c'est la ville actuelle qu'on édite
                      stopData.cityId == city.id
                    ).toList(),
                    onChanged: (newData) {
                      setState(() {
                        _currentStopData = newData;
                      });
                    },
                    showRemoveButton: false,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isAddingStop = false;
                          });
                        },
                        child: const Text("Annuler"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Vérifier que les champs obligatoires sont remplis
                          if (stopData.cityId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Veuillez sélectionner une ville")),
                            );
                            return;
                          }
                          
                          // Déterminer où insérer le nouvel arrêt
                          setState(() {
                            // Si nous insérons un arrêt intermédiaire
                            if (stopType == StopType.intermediaire) {
                              // Trouver où insérer l'arrêt en fonction de son ordre
                              int insertIndex = 0;
                              while (insertIndex < _stopsData.length && 
                                    _stopsData[insertIndex].stopOrder < stopData.stopOrder) {
                                insertIndex++;
                              }
                              
                              // Insérer à la position déterminée
                              _stopsData.insert(insertIndex, stopData);
                              
                              // Réajuster les ordres de tous les arrêts
                              for (int i = 0; i < _stopsData.length; i++) {
                                _stopsData[i] = _stopsData[i].copyWith(
                                  stopOrder: i + 1,
                                  // Ajuster le type pour s'assurer que le dernier est bien arrivée
                                  stopType: i == 0 
                                      ? StopType.depart 
                                      : (i == _stopsData.length - 1 && hasArrivalStop())
                                          ? StopType.arrivee
                                          : _stopsData[i].stopType,
                                );
                              }
                            } else {
                              // Pour le départ et l'arrivée, simplement ajouter
                              _stopsData.add(stopData);
                              _stopsData.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
                              
                              // Réassigner les ordres séquentiellement
                              for (int i = 0; i < _stopsData.length; i++) {
                                _stopsData[i] = _stopsData[i].copyWith(stopOrder: i + 1);
                              }
                            }
                            
                            // Revenir à la vue du Stepper
                            _isAddingStop = false;
                            
                            // Si on a ajouté l'arrêt d'arrivée, marquer comme terminé
                            if (stopType == StopType.arrivee) {
                              _finalStepReached = true;
                            }
                          });
                        },
                        child: const Text("Ajouter cet arrêt"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
