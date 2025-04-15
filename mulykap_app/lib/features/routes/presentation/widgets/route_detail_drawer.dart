import 'package:flutter/material.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/domain/models/route_stop_model.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:mulykap_app/features/routes/presentation/screens/route_stop_form_screen.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_stop_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteDetailDrawer extends StatelessWidget {
  final RouteModel route;
  final Map<String, CityModel> citiesMap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RouteDetailDrawer({
    Key? key,
    required this.route,
    required this.citiesMap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteInfo(context, l10n),
                  const SizedBox(height: 24),
                  _buildDistanceInfo(context, l10n),
                  const SizedBox(height: 24),
                  _buildStopsSection(context, l10n),
                  const SizedBox(height: 24),
                  _buildActions(context, l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final departureCity = citiesMap[route.departureCityId]?.name ?? l10n.unknown;
    final arrivalCity = citiesMap[route.arrivalCityId]?.name ?? l10n.unknown;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.routeDetails,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "$departureCity ➔ $arrivalCity",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context, AppLocalizations l10n) {
    final departureCity = citiesMap[route.departureCityId]?.name ?? l10n.unknown;
    final arrivalCity = citiesMap[route.arrivalCityId]?.name ?? l10n.unknown;
    
    return _buildSection(
      context,
      title: l10n.routeInformation,
      icon: Icons.info_outline,
      children: [
        _buildInfoRow(l10n.departureCity, departureCity),
        _buildInfoRow(l10n.arrivalCity, arrivalCity),
        _buildInfoRow("Date de création", route.createdAt != null 
            ? '${route.createdAt!.day}/${route.createdAt!.month}/${route.createdAt!.year}'
            : l10n.unknown),
      ],
    );
  }

  Widget _buildDistanceInfo(BuildContext context, AppLocalizations l10n) {
    return _buildSection(
      context,
      title: l10n.distance,
      icon: Icons.straighten,
      children: [
        _buildInfoRow(l10n.distanceKm, "${route.distanceKm.toStringAsFixed(1)} km"),
        _buildInfoRow(l10n.estimatedDuration, _formatDuration(route.estimatedDuration)),
      ],
    );
  }

  Widget _buildStopsSection(BuildContext context, AppLocalizations l10n) {
    // Nous devons charger les arrêts existants
    final stopsFuture = _loadStops(context);
    
    return _buildSection(
      context,
      title: "Arrêts",
      icon: Icons.place,
      children: [
        FutureBuilder<List<dynamic>>(
          future: stopsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Text(
                "Erreur lors du chargement des arrêts: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Aucun arrêt configuré pour cet itinéraire"),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_location),
                    label: const Text("Configurer les arrêts"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () => _navigateToStopForm(context),
                  ),
                ],
              );
            }
            
            final stops = snapshot.data![0] as List<RouteStopModel>;
            final citiesMap = snapshot.data![1] as Map<String, CityModel>;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Liste des arrêts
                ...stops.map((stop) {
                  final cityName = citiesMap[stop.cityId]?.name ?? "Ville inconnue";
                  final stopOrder = stop.stopOrder;
                  final stopType = stop.stopType.toString().split('.').last;
                  
                  String stopTypeDisplay;
                  switch (stopType) {
                    case 'depart':
                      stopTypeDisplay = "Départ";
                      break;
                    case 'arrivee':
                      stopTypeDisplay = "Arrivée";
                      break;
                    default:
                      stopTypeDisplay = "Intermédiaire";
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text("$stopOrder"),
                        ),
                        title: Text(cityName),
                        subtitle: Text(stopTypeDisplay),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _navigateToStopForm(context, stopId: stop.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteStop(context, stop.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                // Bouton pour ajouter un nouvel arrêt
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_location),
                    label: const Text("Ajouter un arrêt"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () => _navigateToStopForm(context),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return _buildSection(
      context,
      title: "Actions",
      icon: Icons.settings,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: Text(l10n.edit),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: onEdit,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete, color: Colors.red),
          label: Text(l10n.delete),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: Colors.red,
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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

  // Méthode pour charger les arrêts depuis la BDD
  Future<List<dynamic>> _loadStops(BuildContext context) async {
    try {
      final supabaseClient = Supabase.instance.client;
      final stopRepository = RouteStopRepository(supabaseClient: supabaseClient);
      final cityRepository = CityRepository(supabaseClient: supabaseClient);
      
      // Charger les arrêts et les villes
      final List<RouteStopModel> stops = await stopRepository.getStopsForRoute(route.id);
      final List<CityModel> cities = await cityRepository.getAllCities();
      
      // Préparer la map des villes
      final Map<String, CityModel> citiesMap = {};
      for (final city in cities) {
        citiesMap[city.id] = city;
      }
      
      return [stops, citiesMap];
    } catch (e) {
      throw Exception("Erreur lors du chargement des arrêts: $e");
    }
  }
  
  // Méthode pour ouvrir le formulaire d'arrêt dans une boîte de dialogue
  void _navigateToStopForm(BuildContext context, {String? stopId}) {
    Navigator.of(context).pop();
    
    final supabaseClient = Supabase.instance.client;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        // Faire une fenêtre plus grande pour contenir le Stepper correctement
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RouteStopRepository>(
                create: (context) => RouteStopRepository(
                  supabaseClient: supabaseClient,
                ),
              ),
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
            child: RouteStopFormScreen(routeId: route.id, stopId: stopId),
          ),
        ),
      ),
    );
  }
  
  // Méthode pour supprimer un arrêt
  void _deleteStop(BuildContext context, String stopId) async {
    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Supprimer cet arrêt ?"),
          content: const Text("Êtes-vous sûr de vouloir supprimer cet arrêt ? Cette action est irréversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (shouldDelete == true) {
        final supabaseClient = Supabase.instance.client;
        final stopRepository = RouteStopRepository(supabaseClient: supabaseClient);
        
        await stopRepository.deleteStop(stopId);
        
        // Fermer le drawer pour voir les changements
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Arrêt supprimé avec succès")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la suppression de l'arrêt: $e")),
        );
      }
    }
  }
} 