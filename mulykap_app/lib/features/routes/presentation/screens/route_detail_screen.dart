import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/common/presentation/widgets/app_loading_indicator.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_stop_repository.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/domain/models/route_stop_model.dart';
import 'package:mulykap_app/features/routes/presentation/bloc/route_bloc.dart';
import 'package:mulykap_app/features/routes/presentation/screens/route_form_screen.dart';
import 'package:mulykap_app/features/routes/presentation/screens/route_stop_form_screen.dart';
import 'package:mulykap_app/features/shared/presentation/widgets/app_error_widget.dart';
import 'package:mulykap_app/features/shared/presentation/widgets/confirmation_dialog.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;

  const RouteDetailScreen({
    Key? key,
    required this.routeId,
  }) : super(key: key);

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  RouteModel? _route;
  List<RouteStopModel> _stops = [];
  Map<String, CityModel> _citiesMap = {};
  bool _isLoading = true;
  String? _errorMessage;
  
  late RouteBloc _routeBloc;
  late RouteRepository _routeRepository;
  late RouteStopRepository _routeStopRepository;
  late CityRepository _cityRepository;
  StreamSubscription? _routeBlocSubscription;

  @override
  void initState() {
    super.initState();
    try {
      // Initialiser les repositories et bloc
      final supabaseClient = Supabase.instance.client;
      _routeRepository = RouteRepository(supabaseClient: supabaseClient);
      _routeStopRepository = RouteStopRepository(supabaseClient: supabaseClient);
      _cityRepository = CityRepository(supabaseClient: supabaseClient);
      _routeBloc = RouteBloc(routeRepository: _routeRepository);
      
      // Charger les données
      _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur d'initialisation: ${e.toString()}";
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _routeBlocSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les villes
      final cities = await _cityRepository.getAllCities();
      
      final Map<String, CityModel> citiesMap = {};
      for (final city in cities) {
        citiesMap[city.id] = city;
      }
      
      // Charger l'itinéraire
      final route = await _routeRepository.getRouteById(widget.routeId);
      if (route == null) {
        setState(() {
          _errorMessage = 'Itinéraire non trouvé';
          _isLoading = false;
        });
        return;
      }
      
      // Charger les arrêts
      final stops = await _routeStopRepository.getStopsForRoute(route.id);
      
      setState(() {
        _route = route;
        _stops = stops;
        _citiesMap = citiesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _deleteStop(String stopId) async {
    try {
      await _routeStopRepository.deleteStop(stopId);
      
      // Refresh stops
      if (_route != null) {
        final updatedStops = await _routeStopRepository.getStopsForRoute(_route!.id);
        setState(() {
          _stops = updatedStops;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _addStop() async {
    if (_route == null) return;
    
    final supabaseClient = Supabase.instance.client;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RouteStopRepository>(
              create: (context) => RouteStopRepository(
                supabaseClient: supabaseClient,
              ),
            ),
            RepositoryProvider<CityRepository>(
              create: (context) => CityRepository(
                supabaseClient: supabaseClient,
              ),
            ),
          ],
          child: RouteStopFormScreen(routeId: _route!.id),
        ),
      ),
    );
    
    // Recharger les données après l'ajout
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _editStop(RouteStopModel stop) async {
    if (_route == null) return;
    
    final supabaseClient = Supabase.instance.client;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RouteStopRepository>(
              create: (context) => RouteStopRepository(
                supabaseClient: supabaseClient,
              ),
            ),
            RepositoryProvider<CityRepository>(
              create: (context) => CityRepository(
                supabaseClient: supabaseClient,
              ),
            ),
          ],
          child: RouteStopFormScreen(
            routeId: _route!.id,
            stopId: stop.id,
          ),
        ),
      ),
    );
    
    // Recharger les données après la modification
    if (mounted) {
      _loadData();
    }
  }
  
  void _editRoute() {
    if (_route == null) return;
    
    final supabaseClient = Supabase.instance.client;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiRepositoryProvider(
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
          child: BlocProvider(
            create: (context) => RouteBloc(
              routeRepository: context.read<RouteRepository>(),
            ),
            child: RouteFormScreen(routeId: _route!.id),
          ),
        ),
      ),
    ).then((_) => _loadData());
  }
  
  void _deleteRoute() {
    if (_route == null) return;
    
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: l10n.deleteRoute,
        content: l10n.confirmDeleteRoute,
        confirmText: l10n.delete,
        cancelText: l10n.cancel,
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await _routeRepository.deleteRoute(_route!.id);
          if (mounted) {
            Navigator.pop(context); // Return to routes list
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routeDetails)),
        body: const AppLoadingIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routeDetails)),
        body: AppErrorWidget(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }
    
    if (_route == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routeDetails)),
        body: Center(child: Text(l10n.routeNotFound)),
      );
    }
    
    final departureCity = _citiesMap[_route!.departureCityId]?.name ?? l10n.unknown;
    final arrivalCity = _citiesMap[_route!.arrivalCityId]?.name ?? l10n.unknown;
    
    return BlocProvider(
      create: (context) => _routeBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text("$departureCity ➔ $arrivalCity"),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editRoute,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteRoute,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte d'information sur l'itinéraire
              Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.routeInformation,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.location_city),
                        title: Text(l10n.departureCity),
                        subtitle: Text(departureCity),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_city),
                        title: Text(l10n.arrivalCity),
                        subtitle: Text(arrivalCity),
                      ),
                      ListTile(
                        leading: const Icon(Icons.straighten),
                        title: Text(l10n.distance),
                        subtitle: Text("${_route!.distanceKm.toStringAsFixed(1)} km"),
                      ),
                      ListTile(
                        leading: const Icon(Icons.timer),
                        title: Text(l10n.estimatedDuration),
                        subtitle: Text(_formatDuration(_route!.estimatedDuration)),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Section des arrêts
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.stops,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addStop),
                      onPressed: _addStop,
                    ),
                  ],
                ),
              ),
              
              if (_stops.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(l10n.noStopsFound),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _stops.length,
                  itemBuilder: (context, index) {
                    final stop = _stops[index];
                    final cityName = _citiesMap[stop.cityId]?.name ?? l10n.unknown;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text("${stop.stopOrder}"),
                        ),
                        title: Text(cityName),
                        subtitle: Text(l10n.stopType(stop.stopType.toString().split('.').last)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editStop(stop),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => ConfirmationDialog(
                                    title: l10n.deleteStop,
                                    content: l10n.confirmDeleteStop,
                                    confirmText: l10n.delete,
                                    cancelText: l10n.cancel,
                                  ),
                                );
                                
                                if (shouldDelete == true && mounted) {
                                  await _deleteStop(stop.id);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // Afficher les détails de l'arrêt si nécessaire
                        },
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}