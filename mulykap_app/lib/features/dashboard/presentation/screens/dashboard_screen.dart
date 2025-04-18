import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_state.dart';
import '../widgets/sidebar_menu.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/responsive_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState.user;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final theme = _isDarkMode ? ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF3D5AF1),
        secondary: const Color(0xFFFF9800),
        surface: Colors.grey.shade900,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D5AF1),
        ),
      ),
    ) : ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3D5AF1),
        secondary: const Color(0xFFFF9800),
      ),
      useMaterial3: true,
    );
    
    return Theme(
      data: theme,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        // Drawer pour les appareils mobiles
        drawer: ResponsiveLayout.isMobile(context) 
            ? SidebarMenu(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemTapped,
                isDarkMode: _isDarkMode,
                currentUser: currentUser,
              ) 
            : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Afficher le menu latéral uniquement sur les écrans plus grands
              if (!ResponsiveLayout.isMobile(context))
                SidebarMenu(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemTapped,
                  isDarkMode: _isDarkMode,
                  currentUser: currentUser,
                ),
              
              // Contenu principal du dashboard
              Expanded(
                child: Column(
                  children: [
                    // En-tête du dashboard avec recherche, notifications, etc.
                    DashboardHeader(
                      onMenuTap: () {
                        if (ResponsiveLayout.isMobile(context)) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      },
                      isDarkMode: _isDarkMode,
                      onThemeToggle: _toggleTheme,
                      currentUser: currentUser,
                    ),
                    
                    // Contenu principal qui change en fonction de l'élément sélectionné
                    Expanded(
                      child: DashboardContent(
                        selectedIndex: _selectedIndex,
                        isDarkMode: _isDarkMode,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 