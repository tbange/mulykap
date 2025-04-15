import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/common/presentation/widgets/app_loading_indicator.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_stop_repository.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/domain/models/route_stop_model.dart';
import 'package:mulykap_app/features/routes/presentation/screens/route_stop_form_screen.dart';
import 'package:mulykap_app/features/shared/presentation/widgets/app_error_widget.dart';
import 'package:mulykap_app/utils/app_localizations.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({Key? key}) : super(key: key);

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  late RouteStopRepository _routeStopRepository;
  late RouteRepository _routeRepository;
  late CityRepository _cityRepository;

  bool _isLoading = true;
  String? _errorMessage;

  List<RouteStopModel> _allStops = [];
  List<RouteStopModel> _filteredStops = [];
  List<CityModel> _cities = [];
  List<RouteModel> _routes = [];

  // Filtres
  String? _selectedCityId;
  String? _selectedRouteId;
  String _searchQuery = '';

  // Contrôleur pour la recherche
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _routeStopRepository = context.read<RouteStopRepository>();
    _routeRepository = context.read<RouteRepository>();
    _cityRepository = context.read<CityRepository>();

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger toutes les villes
      final cities = await _cityRepository.getAllCities();
      
      // Charger tous les itinéraires
      final routes = await _routeRepository.getAllRoutes();
      
      // Charger tous les arrêts avec informations enrichies
      final List<RouteStopModel> allStops = [];
      for (var route in routes) {
        final stops = await _routeStopRepository.getStopsForRoute(route.id);
        allStops.addAll(stops);
      }
      
      setState(() {
        _cities = cities;
        _routes = routes;
        _allStops = allStops;
        _filteredStops = allStops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Fonction pour appliquer les filtres
  void _applyFilters() {
    setState(() {
      _filteredStops = _allStops.where((stop) {
        // Filtrer par ville si sélectionnée
        if (_selectedCityId != null && _selectedCityId!.isNotEmpty) {
          if (stop.cityId != _selectedCityId) return false;
        }
        
        // Filtrer par itinéraire si sélectionné
        if (_selectedRouteId != null && _selectedRouteId!.isNotEmpty) {
          if (stop.routeId != _selectedRouteId) return false;
        }
        
        // Appliquer la recherche textuelle
        if (_searchQuery.isNotEmpty) {
          final city = _getCityById(stop.cityId);
          final route = _getRouteById(stop.routeId);
          
          final cityName = city?.name.toLowerCase() ?? '';
          
          // Obtenir les noms des villes de départ et d'arrivée
          final departureCityName = route != null ? _getCityById(route.departureCityId)?.name.toLowerCase() ?? '' : '';
          final arrivalCityName = route != null ? _getCityById(route.arrivalCityId)?.name.toLowerCase() ?? '' : '';
          final routeInfo = '$departureCityName - $arrivalCityName'.toLowerCase();
          
          return cityName.contains(_searchQuery.toLowerCase()) || 
                 routeInfo.contains(_searchQuery.toLowerCase());
        }
        
        return true;
      }).toList();
    });
  }

  // Fonction pour réinitialiser les filtres
  void _resetFilters() {
    setState(() {
      _selectedCityId = null;
      _selectedRouteId = null;
      _searchQuery = '';
      _searchController.clear();
      _filteredStops = _allStops;
    });
  }

  // Récupérer une ville par son ID
  CityModel? _getCityById(String cityId) {
    try {
      return _cities.firstWhere((city) => city.id == cityId);
    } catch (e) {
      return null;
    }
  }

  // Récupérer un itinéraire par son ID
  RouteModel? _getRouteById(String routeId) {
    try {
      return _routes.firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }

  // Naviguer vers le formulaire d'édition d'arrêt
  void _navigateToStopForm(String routeId, {String? stopId}) async {
    final result = await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(
            maxWidth: 800,
            maxHeight: 800,
          ),
          // Important: Fournir les repositories dans le contexte du dialogue
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RouteStopRepository>.value(
                value: _routeStopRepository,
              ),
              RepositoryProvider<RouteRepository>.value(
                value: _routeRepository,
              ),
              RepositoryProvider<CityRepository>.value(
                value: _cityRepository,
              ),
            ],
            child: RouteStopFormScreen(
              routeId: routeId,
              stopId: stopId,
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      _loadData(); // Recharger les données si modification
    }
  }

  // Supprimer un arrêt
  void _deleteStop(RouteStopModel stop) async {
    // Demander confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet arrêt?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Supprimer'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _routeStopRepository.deleteStop(stop.id);
        _loadData(); // Recharger les données
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(
        child: AppLoadingIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: AppErrorWidget(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des Arrêts',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtres
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtres',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Recherche textuelle
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Rechercher',
                            hintText: 'Rechercher par ville ou itinéraire',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Filtre par ville
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Filtrer par ville',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCityId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Toutes les villes'),
                            ),
                            ..._cities.map((city) => DropdownMenuItem<String?>(
                              value: city.id,
                              child: Text(city.name),
                            )).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCityId = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Filtre par itinéraire
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Filtrer par itinéraire',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedRouteId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tous les itinéraires'),
                            ),
                            ..._routes.map((route) {
                              final departureCityName = _getCityById(route.departureCityId)?.name ?? '?';
                              final arrivalCityName = _getCityById(route.arrivalCityId)?.name ?? '?';
                              return DropdownMenuItem<String?>(
                                value: route.id,
                                child: Text('$departureCityName → $arrivalCityName'),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRouteId = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Réinitialiser les filtres'),
                        onPressed: _resetFilters,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Liste des arrêts
          Expanded(
            child: _filteredStops.isEmpty
                ? Center(
                    child: Text(
                      'Aucun arrêt trouvé',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )
                : Card(
                    child: ListView(
                      children: [
                        // En-tête du tableau
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Itinéraire',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Ville',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Type',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Ordre',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Distance',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Durée',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 100),
                            ],
                          ),
                        ),
                        
                        // Corps du tableau
                        ...List.generate(_filteredStops.length, (index) {
                          final stop = _filteredStops[index];
                          final city = _getCityById(stop.cityId);
                          final route = _getRouteById(stop.routeId);
                          
                          // Informations sur les villes de l'itinéraire
                          final departureCityName = _getCityById(route?.departureCityId ?? '')?.name ?? '?';
                          final arrivalCityName = _getCityById(route?.arrivalCityId ?? '')?.name ?? '?';
                          
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.transparent
                                  : Theme.of(context).colorScheme.surface.withOpacity(0.1),
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Itinéraire
                                Expanded(
                                  flex: 2,
                                  child: Text('$departureCityName → $arrivalCityName'),
                                ),
                                
                                // Ville de l'arrêt
                                Expanded(
                                  flex: 2,
                                  child: Text(city?.name ?? 'Ville inconnue'),
                                ),
                                
                                // Type d'arrêt
                                Expanded(
                                  child: Text(stop.stopType.displayName),
                                ),
                                
                                // Ordre de l'arrêt
                                Expanded(
                                  child: Text(stop.stopOrder.toString()),
                                ),
                                
                                // Distance depuis l'arrêt précédent
                                Expanded(
                                  child: Text(
                                    stop.distanceFromPrevious != null
                                        ? '${stop.distanceFromPrevious!.toStringAsFixed(1)} km'
                                        : '-'
                                  ),
                                ),
                                
                                // Durée depuis l'arrêt précédent
                                Expanded(
                                  child: Text(
                                    stop.durationFromPrevious != null
                                        ? '${stop.durationFromPrevious!.inHours}h${stop.durationFromPrevious!.inMinutes.remainder(60)}m'
                                        : '-'
                                  ),
                                ),
                                
                                // Actions
                                SizedBox(
                                  width: 100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'Modifier',
                                        onPressed: () => _navigateToStopForm(stop.routeId, stopId: stop.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'Supprimer',
                                        onPressed: () => _deleteStop(stop),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 