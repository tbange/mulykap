import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/common/presentation/widgets/app_loading_indicator.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/responsive_layout.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_stop_repository.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/presentation/bloc/route_bloc.dart';
import 'package:mulykap_app/features/routes/presentation/screens/route_detail_screen.dart';
import 'package:mulykap_app/features/routes/presentation/screens/route_form_screen.dart';
import 'package:mulykap_app/features/routes/presentation/widgets/route_detail_drawer.dart';
import 'package:mulykap_app/features/shared/presentation/widgets/app_error_widget.dart';
import 'package:mulykap_app/features/shared/presentation/widgets/confirmation_dialog.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({Key? key}) : super(key: key);

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late RouteRepository _routeRepository;
  late RouteBloc _routeBloc;
  bool _isLoadingCities = false;
  Map<String, CityModel> _citiesMap = {};
  String? _errorLoadingCities;
  final TextEditingController _searchController = TextEditingController();
  List<RouteModel> _filteredRoutes = [];
  String _selectedDepartureCity = '';
  String _selectedArrivalCity = '';
  List<String> _departureCities = [];
  List<String> _arrivalCities = [];
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RouteModel? _selectedRoute;
  
  @override
  void initState() {
    super.initState();
    
    // Utiliser le bloc fourni par le contexte
    debugPrint('Routes Screen: initialisation');
    
    try {
      _routeRepository = RepositoryProvider.of<RouteRepository>(context);
      debugPrint('Routes Screen: repository récupéré du provider');
      
      // Utiliser le bloc fourni par le BlocProvider parent
      _routeBloc = BlocProvider.of<RouteBloc>(context);
      debugPrint('Routes Screen: bloc récupéré du provider');
      
      // Initialiser le chargement des données
      _loadCitiesDirectly();
      
      // Inutile d'appeler explicitement _loadRoutes car le BlocProvider le fait déjà
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRoutesAndCities() {
    debugPrint('Routes Screen: loadRoutesAndCities');
    // Utiliser directement le bloc qui est déjà initialisé
    if (_routeBloc.state is! RouteLoading) {
      _loadRoutes();
    }
    
    if (!_isLoadingCities) {
      _loadCitiesDirectly();
    }
  }

  void _loadRoutes() {
    _routeBloc.add(const LoadRoutes());
  }

  Future<void> _loadCitiesDirectly() async {
    setState(() {
      _isLoadingCities = true;
    });
    
    try {
      // Créer directement un repository sans l'obtenir du contexte
      final cityRepository = CityRepository(
        supabaseClient: Supabase.instance.client,
      );
      
      final cities = await cityRepository.getAllCities();
      
      final Map<String, CityModel> citiesMap = {};
      for (final city in cities) {
        citiesMap[city.id] = city;
      }
      
      debugPrint('Villes chargées: ${cities.length}');
      
      if (mounted) {
        setState(() {
          _citiesMap = citiesMap;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des villes: $e');
      if (mounted) {
        setState(() {
          _errorLoadingCities = e.toString();
          _isLoadingCities = false;
        });
      }
    }
  }

  void _filterRoutes(List<RouteModel> routes) {
    final searchQuery = _searchController.text.toLowerCase();
    
    // Extraire toutes les villes de départ et d'arrivée si nécessaire
    if (_departureCities.isEmpty && routes.isNotEmpty && _citiesMap.isNotEmpty) {
      final Set<String> uniqueDepartureCities = routes
          .map((route) => _citiesMap[route.departureCityId]?.name ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
          
      final Set<String> uniqueArrivalCities = routes
          .map((route) => _citiesMap[route.arrivalCityId]?.name ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
          
      List<String> depCitiesList = uniqueDepartureCities.toList()..sort();
      List<String> arrCitiesList = uniqueArrivalCities.toList()..sort();
      
      depCitiesList.insert(0, 'Toutes les villes de départ');
      arrCitiesList.insert(0, 'Toutes les villes d\'arrivée');
      
      _departureCities = depCitiesList;
      _arrivalCities = arrCitiesList;
    }
    
    final filtered = routes.where((route) {
      final departureCity = _citiesMap[route.departureCityId]?.name ?? '';
      final arrivalCity = _citiesMap[route.arrivalCityId]?.name ?? '';
      
      final matchesSearch = 
          departureCity.toLowerCase().contains(searchQuery) ||
          arrivalCity.toLowerCase().contains(searchQuery) ||
          '${departureCity.toLowerCase()} - ${arrivalCity.toLowerCase()}'.contains(searchQuery);
          
      final matchesDepartureCity = _selectedDepartureCity.isEmpty || 
          _selectedDepartureCity == 'Toutes les villes de départ' || 
          departureCity == _selectedDepartureCity;
          
      final matchesArrivalCity = _selectedArrivalCity.isEmpty || 
          _selectedArrivalCity == 'Toutes les villes d\'arrivée' || 
          arrivalCity == _selectedArrivalCity;
          
      return matchesSearch && matchesDepartureCity && matchesArrivalCity;
    }).toList();
    
    // N'utiliser setState que si le widget est toujours monté
    if (mounted) {
      setState(() {
        _filteredRoutes = filtered;
      });
    }
  }

  void _editRoute(String? routeId) {
    final supabaseClient = Supabase.instance.client;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RouteRepository>(
                create: (context) => RouteRepository(
                  supabaseClient: supabaseClient,
                ),
              ),
              RepositoryProvider<CityRepository>(
                create: (context) => CityRepository(
                  supabaseClient: supabaseClient,
                ),
              ),
            ],
            child: BlocProvider.value(
              value: _routeBloc,
              child: RouteFormScreen(routeId: routeId),
            ),
          ),
        ),
      ),
    ).then((_) => _loadRoutesAndCities());
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(l10n.routes),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _editRoute(null),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadRoutesAndCities(),
          ),
        ],
      ),
      endDrawer: _selectedRoute != null
          ? RouteDetailDrawer(
              route: _selectedRoute!,
              citiesMap: _citiesMap,
              onEdit: () {
                Navigator.of(context).pop(); // Fermer le drawer
                _editRoute(_selectedRoute!.id);
              },
              onDelete: () {
                Navigator.of(context).pop(); // Fermer le drawer
                _showDeleteConfirmation(context, _selectedRoute!);
              },
            )
          : null,
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: l10n.search,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        hintText: l10n.searchRoutesHint,
                      ),
                      onChanged: (_) {
                        if (!_isLoadingCities) {
                          final state = _routeBloc.state;
                          if (state is RouteLoaded) {
                            _filterRoutes(state.routes);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.filterByDepartureCity,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<RouteBloc, RouteState>(
                      builder: (context, state) {
                        if (state is RouteLoading || _isLoadingCities) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _departureCities.map((city) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(city),
                                  selected: _selectedDepartureCity == city,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedDepartureCity = selected ? city : '';
                                      if (state is RouteLoaded) {
                                        _filterRoutes(state.routes);
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.filterByArrivalCity,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<RouteBloc, RouteState>(
                      builder: (context, state) {
                        if (state is RouteLoading || _isLoadingCities) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _arrivalCities.map((city) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(city),
                                  selected: _selectedArrivalCity == city,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedArrivalCity = selected ? city : '';
                                      if (state is RouteLoaded) {
                                        _filterRoutes(state.routes);
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Liste des itinéraires
          Expanded(
            child: BlocConsumer<RouteBloc, RouteState>(
              listener: (context, state) {
                if (state is RouteLoaded && !_isLoadingCities) {
                  // Appliquer le filtre uniquement lorsque les itinéraires changent
                  // Utiliser Future.microtask pour s'assurer que setState est appelé après le build
                  Future.microtask(() => _filterRoutes(state.routes));
                }
                if (state is RouteError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is RouteInitial) {
                  debugPrint('État RouteInitial, démarrage du chargement...');
                  _loadRoutesAndCities();
                  return const AppLoadingIndicator();
                } else if (state is RouteLoading || _isLoadingCities) {
                  debugPrint('État RouteLoading ou chargement des villes en cours...');
                  return const AppLoadingIndicator();
                } else if (state is RouteLoaded) {
                  debugPrint('État RouteLoaded, routes chargées: ${state.routes.length}');
                  
                  // Initialiser _filteredRoutes si nécessaire
                  if (_filteredRoutes.isEmpty && state.routes.isNotEmpty && !_isLoadingCities) {
                    debugPrint('Filtrage initial des routes...');
                    Future.microtask(() => _filterRoutes(state.routes));
                    return const AppLoadingIndicator();
                  }
                  
                  if (_filteredRoutes.isEmpty) {
                    debugPrint('Aucune route filtrée à afficher');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.route,
                            color: Colors.grey,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty || 
                            _selectedDepartureCity.isNotEmpty || 
                            _selectedArrivalCity.isNotEmpty
                                ? l10n.noRoutesMatchSearch
                                : l10n.noRoutesFound,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (_searchController.text.isEmpty && 
                              _selectedDepartureCity.isEmpty && 
                              _selectedArrivalCity.isEmpty)
                            ElevatedButton(
                              onPressed: () => _editRoute(null),
                              child: Text(l10n.addRoute),
                            ),
                        ],
                      ),
                    );
                  }
                  
                  debugPrint('Affichage de ${_filteredRoutes.length} routes');
                  return ResponsiveLayout(
                    mobile: _buildRoutesList(context, _filteredRoutes),
                    tablet: _buildRoutesList(context, _filteredRoutes),
                    desktop: _buildRoutesTable(context, _filteredRoutes),
                  );
                } else if (state is RouteError) {
                  debugPrint('État RouteError: ${state.message}');
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: _loadRoutesAndCities,
                  );
                }
                
                debugPrint('État non géré: ${state.runtimeType}');
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editRoute(null),
        tooltip: 'Ajouter un itinéraire',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildRoutesList(BuildContext context, List<RouteModel> routes) {
    final l10n = AppLocalizations.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return _buildRouteCard(context, route);
      },
    );
  }
  
  Widget _buildRoutesTable(BuildContext context, List<RouteModel> routes) {
    final l10n = AppLocalizations.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Container(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  DataColumn(label: Text(l10n.departureCity)),
                  DataColumn(label: Text(l10n.arrivalCity)),
                  DataColumn(label: Text(l10n.distance)),
                  DataColumn(label: Text(l10n.estimatedDuration)),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: routes.map((route) {
                  final departureCity = _citiesMap[route.departureCityId]?.name ?? l10n.unknown;
                  final arrivalCity = _citiesMap[route.arrivalCityId]?.name ?? l10n.unknown;
                
                  return DataRow(
                    cells: [
                      DataCell(Text(departureCity)),
                      DataCell(Text(arrivalCity)),
                      DataCell(Text("${route.distanceKm.toStringAsFixed(0)} km")),
                      DataCell(Text(_formatDuration(route.estimatedDuration))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              tooltip: l10n.viewDetails,
                              onPressed: () => _openRouteDetail(route),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: l10n.edit,
                              onPressed: () => _editRoute(route.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: l10n.delete,
                              onPressed: () => _showDeleteConfirmation(context, route),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _openRouteDetail(RouteModel route) {
    setState(() {
      _selectedRoute = route;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }
  
  Future<void> _showDeleteConfirmation(BuildContext context, RouteModel route) async {
    final l10n = AppLocalizations.of(context);
    final departureCity = _citiesMap[route.departureCityId]?.name ?? l10n.unknown;
    final arrivalCity = _citiesMap[route.arrivalCityId]?.name ?? l10n.unknown;
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: l10n.deleteRoute,
        content: l10n.confirmDeleteRoute,
        confirmText: l10n.delete,
        cancelText: l10n.cancel,
      ),
    );
    
    if (shouldDelete == true && context.mounted) {
      _routeBloc.add(DeleteRoute(routeId: route.id));
    }
  }
  
  Widget _buildRouteCard(BuildContext context, RouteModel route) {
    final l10n = AppLocalizations.of(context);
    
    // Récupérer les informations de la ville
    final departureCity = _citiesMap[route.departureCityId]?.name ?? l10n.loading;
    final arrivalCity = _citiesMap[route.arrivalCityId]?.name ?? l10n.loading;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(
            Icons.route,
            color: Colors.white,
          ),
        ),
        title: Text(
          "$departureCity ➔ $arrivalCity",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(_formatDuration(route.estimatedDuration)),
                const SizedBox(width: 16),
                Icon(Icons.straighten, size: 16, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text("${route.distanceKm.toStringAsFixed(0)} km"),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.edit,
              onPressed: () => _editRoute(route.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n.delete,
              onPressed: () => _showDeleteConfirmation(context, route),
            ),
          ],
        ),
        onTap: () => _openRouteDetail(route),
      ),
    );
  }
} 