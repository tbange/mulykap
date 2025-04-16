import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mulykap_app/common/domain/enums/user_role.dart';
import 'package:mulykap_app/features/agencies/presentation/screens/agency_list_screen.dart';
import 'package:mulykap_app/features/authentication/domain/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/screens/bus_list_screen.dart';
import 'package:mulykap_app/features/cities/presentation/screens/city_list_screen.dart';
import 'package:mulykap_app/features/dashboard/domain/models/menu_item.dart';
import 'package:mulykap_app/features/dashboard/presentation/dashboard_content.dart';
import 'package:mulykap_app/features/drivers/presentation/screens/driver_list_screen.dart';
import 'package:mulykap_app/features/routes/presentation/screens/route_list_screen.dart';
import 'package:mulykap_app/features/stops/presentation/screens/stops_screen.dart';
import 'package:mulykap_app/features/trips/presentation/screens/trip_list_screen.dart';
import 'package:mulykap_app/features/users/presentation/screens/user_list_screen.dart';
import 'package:mulykap_app/utils/app_localizations.dart';

class DashboardMenu extends StatelessWidget {
  final Function(Widget) onPageSelected;
  final String currentPageId;

  const DashboardMenu({
    Key? key,
    required this.onPageSelected,
    required this.currentPageId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.read<AuthBloc>().state;
    final userRole = authState.maybeWhen(
      authenticated: (user) => user.role,
      orElse: () => UserRole.client,
    );

    final menuItems = [
      // Tableau de bord (Home)
      MenuItem(
        id: 'dashboard',
        icon: 'assets/icons/dashboard.svg',
        title: l10n.dashboard,
        page: const DashboardContent(),
        allowedRoles: [UserRole.admin, UserRole.staff, UserRole.agent],
      ),
      // Gestion des utilisateurs
      MenuItem(
        id: 'users',
        icon: 'assets/icons/users.svg',
        title: l10n.users,
        page: const UserListScreen(),
        allowedRoles: [UserRole.admin],
      ),
      // Gestion des agences
      MenuItem(
        id: 'agencies',
        icon: 'assets/icons/agency.svg',
        title: l10n.agencies,
        page: const AgencyListScreen(),
        allowedRoles: [UserRole.admin],
      ),
      // Gestion des villes
      MenuItem(
        id: 'cities',
        icon: 'assets/icons/city.svg',
        title: l10n.cities,
        page: const CityListScreen(),
        allowedRoles: [UserRole.admin],
      ),
      // Gestion des itinéraires
      MenuItem(
        id: 'routes',
        icon: 'assets/icons/route.svg',
        title: l10n.routes,
        page: const RouteListScreen(),
        allowedRoles: [UserRole.admin, UserRole.staff],
      ),
      // Gestion des arrêts
      MenuItem(
        id: 'stops',
        icon: 'assets/icons/stop.svg',
        title: l10n.stops,
        page: const StopsScreen(),
        allowedRoles: [UserRole.admin, UserRole.staff],
      ),
      // Gestion des bus
      MenuItem(
        id: 'buses',
        icon: 'assets/icons/bus.svg',
        title: l10n.buses,
        page: const BusListScreen(),
        allowedRoles: [UserRole.admin, UserRole.staff, UserRole.agent],
      ),
      // Gestion des chauffeurs
      MenuItem(
        id: 'drivers',
        icon: 'assets/icons/driver.svg',
        title: l10n.drivers,
        page: const DriverListScreen(),
        allowedRoles: [UserRole.admin, UserRole.staff, UserRole.agent],
      ),
      // Gestion des voyages
      MenuItem(
        id: 'trips',
        icon: 'assets/icons/trip.svg',
        title: l10n.trips,
        page: const TripListScreen(),
        allowedRoles: [UserRole.admin, UserRole.staff, UserRole.agent],
      ),
    ];

    // Filtrer les éléments de menu selon le rôle de l'utilisateur
    final filteredItems = menuItems
        .where((item) => item.allowedRoles.contains(userRole))
        .toList();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final isSelected = currentPageId == item.id;

        return ListTile(
          leading: SvgPicture.asset(
            item.icon,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
              BlendMode.srcIn,
            ),
            width: 24,
            height: 24,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade800,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          selected: isSelected,
          onTap: () => onPageSelected(item.page),
        );
      },
    );
  }
} 