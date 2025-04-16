import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/overview_screen.dart';
import 'responsive_layout.dart';
import 'package:mulykap_app/features/buses/presentation/screens/bus_list_screen.dart';
import 'package:mulykap_app/features/buses/presentation/screens/agency_list_screen.dart';
import 'package:mulykap_app/features/buses/presentation/screens/city_list_screen.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_stop_repository.dart';
import 'package:mulykap_app/features/routes/presentation/bloc/route_bloc.dart';
import 'package:mulykap_app/features/routes/presentation/screens/routes_screen.dart';
import 'package:mulykap_app/features/routes/presentation/screens/stops_screen.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/drivers/presentation/screens/driver_list_screen.dart';
import 'package:mulykap_app/features/recurring_trips/recurring_trips.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardContent extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;

  const DashboardContent({
    Key? key,
    required this.selectedIndex,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sélectionner le contenu en fonction de l'index
    switch (selectedIndex) {
      case 0:
        return OverviewScreen(isDarkMode: isDarkMode);
      case 1:
        return const BusListScreen();
      case 2:
        // Créer directement les instances des dépendances
        final supabaseClient = Supabase.instance.client;
        final routeRepository = RouteRepository(supabaseClient: supabaseClient);
        final routeStopRepository = RouteStopRepository(supabaseClient: supabaseClient);
        
        // Utilisons un BlocProvider frais à chaque fois
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RouteRepository>.value(
              value: routeRepository,
            ),
            RepositoryProvider<RouteStopRepository>.value(
              value: routeStopRepository,
            ),
          ],
          child: BlocProvider<RouteBloc>(
            create: (context) {
              debugPrint('Création d\'un nouveau RouteBloc avec repository');
              return RouteBloc(routeRepository: routeRepository);
            },
            child: Builder(
              builder: (context) {
                debugPrint('Construction de RoutesScreen');
                return const RoutesScreen();
              },
            ),
          ),
        );
      case 3:
        // Créer les dépendances pour l'écran des arrêts
        final supabaseClient = Supabase.instance.client;
        final routeRepository = RouteRepository(supabaseClient: supabaseClient);
        final routeStopRepository = RouteStopRepository(supabaseClient: supabaseClient);
        final cityRepository = CityRepository(supabaseClient: supabaseClient);
        
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RouteRepository>.value(
              value: routeRepository,
            ),
            RepositoryProvider<RouteStopRepository>.value(
              value: routeStopRepository,
            ),
            RepositoryProvider<CityRepository>.value(
              value: cityRepository,
            ),
          ],
          child: const StopsScreen(),
        );
      case 4:
        // Créer les dépendances pour l'écran des voyages récurrents
        final supabaseClient = Supabase.instance.client;
        final recurringTripRepository = RecurringTripRepository(supabaseClient: supabaseClient);
        
        return BlocProvider(
          create: (context) => RecurringTripBloc(
            repository: recurringTripRepository,
          ),
          child: const RecurringTripListScreen(),
        );
      case 5:
        return _buildPlaceholder('Maintenance');
      case 6:
        // Écran de gestion des chauffeurs
        return const DriverListScreen();
      case 7:
        return const AgencyListScreen();
      case 8:
        return const CityListScreen();
      case 9:
        return _buildPlaceholder('Réservations');
      case 10:
        return _buildPlaceholder('Sièges & Bagages');
      case 11:
        return _buildPlaceholder('Tickets');
      case 12:
        return _buildPlaceholder('Paiements');
      case 13:
        return _buildPlaceholder('Promotions');
      case 14:
        return _buildPlaceholder('Notifications');
      case 15:
        return _buildPlaceholder('Statistiques');
      case 16:
        return _buildPlaceholder('Rapports');
      case 17:
        return _buildPlaceholder('Utilisateurs');
      case 18:
        return _buildPlaceholder('Configuration');
      default:
        return OverviewScreen(isDarkMode: isDarkMode);
    }
  }

  Widget _buildPlaceholder(String title) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  'Section $title',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cette fonctionnalité est en cours de développement',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Retourner à la vue générale
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AF1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Revenir à l\'accueil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
} 