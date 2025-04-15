import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/domain/models/user_model.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_event.dart';
import 'responsive_layout.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onMenuTap;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final UserModel currentUser;

  const DashboardHeader({
    Key? key,
    required this.onMenuTap,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Afficher le menu burger uniquement sur mobile
          if (ResponsiveLayout.isMobile(context))
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap,
            ),
          
          // Titre de la page / fil d'Ariane
          if (!ResponsiveLayout.isMobile(context))
            Text(
              'Tableau de bord',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF333333),
              ),
            ),
          
          const Spacer(),
          
          // Barre de recherche
          if (!ResponsiveLayout.isMobile(context))
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          
          const SizedBox(width: 15),
          
          // Bouton pour basculer entre les modes sombre et clair
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: isDarkMode ? Colors.yellow.shade600 : Colors.blue.shade800,
              ),
              tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
              onPressed: onThemeToggle,
            ),
          ),
          
          const SizedBox(width: 15),
          
          // Icône de notification avec badge
          _buildNotificationIcon(),
          
          const SizedBox(width: 15),
          
          // Menu déroulant de l'utilisateur
          if (!ResponsiveLayout.isMobile(context))
            _buildUserDropdownMenu(context),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          iconSize: 28,
          onPressed: () {
            // Action notification
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, width: 2),
            ),
            child: const Center(
              child: Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserDropdownMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: isDarkMode ? const Color(0xFF252525) : Colors.white,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Mon profil',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Paramètres',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuDivider(
          height: 1,
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red.shade400,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'profile':
            // Naviguer vers la page de profil
            Navigator.of(context).pushNamed('/profile');
            break;
          case 'settings':
            // Naviguer vers la page des paramètres
            Navigator.of(context).pushNamed('/settings');
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800.withOpacity(0.4) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
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
            if (ResponsiveLayout.isDesktop(context))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleLogout(BuildContext context) {
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
} 