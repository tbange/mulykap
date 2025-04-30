import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/domain/models/user_model.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_event.dart';
import 'responsive_layout.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isDarkMode;
  final UserModel currentUser;

  const SidebarMenu({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDarkMode,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveLayout.isMobile(context) ? 270 : 250,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          // Logo et titre
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.jpg',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCA28),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                ),
                const SizedBox(width: 10),
                Text(
                  'MulyKap',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          
          // Menu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Catégorie Dashboard
                  _buildCategory(context, 'TABLEAU DE BORD'),
                  
                  // Éléments du dashboard
                  _buildNavItem(
                    context, 
                    0, 
                    Icons.dashboard_rounded, 
                    'Vue Générale',
                  ),
                  
                  // Section transport
                  _buildCategory(context, 'TRANSPORT'),
                  
                  _buildNavItem(
                    context, 
                    1, 
                    Icons.directions_bus_rounded, 
                    'Gestion des Bus',
                  ),
                  _buildNavItem(
                    context, 
                    2, 
                    Icons.map_rounded, 
                    'Itinéraires',
                  ),
                  _buildNavItem(
                    context, 
                    3, 
                    Icons.route_rounded, 
                    'Arrêts',
                  ),
                  _buildNavItem(
                    context, 
                    4, 
                    Icons.schedule_rounded, 
                    'Voyages Récurrents',
                  ),
                  _buildNavItem(
                    context, 
                    5, 
                    Icons.directions_transit_rounded, 
                    'Voyages',
                  ),
                  _buildNavItem(
                    context, 
                    6, 
                    Icons.build_rounded, 
                    'Maintenance',
                  ),
                  _buildNavItem(
                    context, 
                    7, 
                    Icons.people_rounded, 
                    'Chauffeurs',
                  ),
                  _buildNavItem(
                    context, 
                    8, 
                    Icons.business_rounded, 
                    'Agences',
                  ),
                  _buildNavItem(
                    context, 
                    9, 
                    Icons.location_city_rounded, 
                    'Villes',
                  ),
                  
                  // Section Réservations et Paiements
                  _buildCategory(context, 'VENTES'),
                  
                  _buildNavItem(
                    context, 
                    10, 
                    Icons.event_seat_rounded, 
                    'Réservations',
                  ),
                  _buildNavItem(
                    context, 
                    11, 
                    Icons.airline_seat_recline_normal_rounded, 
                    'Sièges & Bagages',
                  ),
                  _buildNavItem(
                    context, 
                    12, 
                    Icons.confirmation_number_rounded, 
                    'Tickets',
                  ),
                  _buildNavItem(
                    context, 
                    13, 
                    Icons.payment_rounded, 
                    'Paiements',
                  ),
                  _buildNavItem(
                    context, 
                    14, 
                    Icons.discount_rounded, 
                    'Promotions',
                  ),
                  
                  // Catégorie Communications
                  _buildCategory(context, 'COMMUNICATIONS'),
                  
                  _buildNavItem(
                    context, 
                    15, 
                    Icons.notifications_rounded, 
                    'Notifications',
                  ),
                  
                  // Catégorie Rapports
                  _buildCategory(context, 'RAPPORTS'),
                  
                  _buildNavItem(
                    context, 
                    16, 
                    Icons.insert_chart_rounded, 
                    'Statistiques',
                  ),
                  _buildNavItem(
                    context, 
                    17, 
                    Icons.summarize_rounded, 
                    'Rapports',
                  ),
                  
                  // Catégorie Paramètres
                  _buildCategory(context, 'PARAMÈTRES'),
                  
                  _buildNavItem(
                    context, 
                    18, 
                    Icons.people_alt_rounded, 
                    'Utilisateurs',
                  ),
                  _buildNavItem(
                    context, 
                    19, 
                    Icons.settings_rounded, 
                    'Configuration',
                  ),
                ],
              ),
            ),
          ),
          
          // Profil utilisateur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    color: isDarkMode ? Colors.blue.shade200 : Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentUser.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        currentUser.displayRole,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Action déconnexion
                    _handleLogout(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    // Afficher une boîte de dialogue de confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          'Déconnexion',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Fermer la boîte de dialogue
              Navigator.of(context).pop();
              
              // Déclencher l'événement de déconnexion
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              
              // Rediriger vers la page de connexion
              Navigator.of(context).pushReplacementNamed('/signin');
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String title) {
    final bool isSelected = selectedIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDarkMode ? const Color(0xFF3D5AF1).withOpacity(0.2) : const Color(0xFF3D5AF1).withOpacity(0.1))
                : Colors.transparent,
            border: isSelected
                ? Border(
                    left: BorderSide(
                      color: const Color(0xFF3D5AF1),
                      width: 3,
                    ),
                  )
                : null,
          ),
          padding: EdgeInsets.only(
            left: isSelected ? 17 : 20,
            right: 20,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? const Color(0xFF3D5AF1)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected 
                      ? const Color(0xFF3D5AF1)
                      : (isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 