import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/upcoming_trips_widget.dart';

class OverviewScreen extends StatelessWidget {
  final bool isDarkMode;
  
  const OverviewScreen({
    Key? key, 
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la page
          Text(
            'Vue Générale',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Bienvenue sur votre tableau de bord, découvrez les informations clés',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 30),
          
          // Cartes statistiques
          _buildStatCards(context),
          
          const SizedBox(height: 30),
          
          // Widgets complexes - disposition différente selon la taille d'écran
          ResponsiveLayout.isDesktop(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Graphique des Réservations récentes (2/3 de l'écran)
                    Expanded(
                      flex: 2,
                      child: _buildReservationChart(context),
                    ),
                    const SizedBox(width: 20),
                    // Transactions récentes (1/3 de l'écran)
                    Expanded(
                      flex: 1,
                      child: RecentTransactionsWidget(isDarkMode: isDarkMode),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildReservationChart(context),
                    const SizedBox(height: 20),
                    RecentTransactionsWidget(isDarkMode: isDarkMode),
                  ],
                ),
          
          const SizedBox(height: 30),
          
          // Prochains voyages
          UpcomingTripsWidget(isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    // Disposition différente selon la taille d'écran
    final isTablet = ResponsiveLayout.isTablet(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    
    // Définir le nombre de cartes par ligne selon la taille de l'écran
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      children: [
        StatCard(
          title: 'Total Réservations',
          value: '1,286',
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFF3D5AF1),
          iconBgColor: const Color(0xFFECF0FF),
          trend: 12.5,
          isDarkMode: isDarkMode,
        ),
        StatCard(
          title: 'Revenus',
          value: '32,567 €',
          icon: Icons.euro_rounded,
          iconColor: const Color(0xFF0DBF7D),
          iconBgColor: const Color(0xFFE0F8F0),
          trend: 8.2,
          isDarkMode: isDarkMode,
        ),
        StatCard(
          title: 'Voyages Actifs',
          value: '38',
          icon: Icons.directions_bus_rounded,
          iconColor: const Color(0xFFFF9800),
          iconBgColor: const Color(0xFFFFF5E5),
          trend: -2.5,
          isDarkMode: isDarkMode,
        ),
        StatCard(
          title: 'Utilisateurs',
          value: '857',
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFFE91E63),
          iconBgColor: const Color(0xFFFCE8EF),
          trend: 5.8,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildReservationChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réservations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  _buildChartFilterItem('Semaine', true),
                  _buildChartFilterItem('Mois', false),
                  _buildChartFilterItem('Année', false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // Placeholder pour le graphique de réservations
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_chart_outlined_rounded,
                    size: 60,
                    color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Graphique des réservations',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Implémentation avec fl_chart à venir',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Mini statistiques sous le graphique
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Aujourd\'hui', '42 réservations'),
              _buildMiniStat('Cette semaine', '256 réservations'),
              _buildMiniStat('Ce mois', '1,286 réservations'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartFilterItem(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF3D5AF1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3D5AF1)
              : isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected 
              ? Colors.white 
              : isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
} 