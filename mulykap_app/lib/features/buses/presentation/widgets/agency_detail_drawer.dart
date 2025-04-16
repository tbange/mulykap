import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_event.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/bus_form_dialog.dart';

class AgencyDetailDrawer extends StatelessWidget {
  final AgencyModel agency;
  final VoidCallback? onEdit;

  const AgencyDetailDrawer({
    Key? key,
    required this.agency,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralInfo(context),
                  const SizedBox(height: 24),
                  _buildAddress(context),
                  const SizedBox(height: 24),
                  _buildContact(context),
                  const SizedBox(height: 24),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                'Détails de l\'Agence',
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
            agency.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          Text(
            'Code: ${agency.code}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfo(BuildContext context) {
    return _buildSection(
      context,
      title: 'Informations générales',
      icon: Icons.info_outline,
      children: [
        _buildCityInfo(context),
      ],
    );
  }

  Widget _buildCityInfo(BuildContext context) {
    return FutureBuilder<CityModel>(
      future: context.read<CityBloc>().state.cities.isNotEmpty 
        ? Future.value(context.read<CityBloc>().state.cities.firstWhere(
            (c) => c.id == agency.cityId, 
            orElse: () => CityModel(id: '', code: '', name: 'Inconnu', province: '', isMain: false)))
        : context.read<CityRepository>().getCityById(agency.cityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInfoRow('Ville:', 'Chargement...');
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildInfoRow('Ville:', 'Non disponible');
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Ville:', snapshot.data!.name),
            _buildInfoRow('Province:', snapshot.data!.province),
          ],
        );
      },
    );
  }

  Widget _buildAddress(BuildContext context) {
    final hasStreet = agency.address['street'] != null && agency.address['street'].toString().isNotEmpty;
    final hasCity = agency.address['city'] != null && agency.address['city'].toString().isNotEmpty;
    final hasZipCode = agency.address['zip_code'] != null && agency.address['zip_code'].toString().isNotEmpty;
    final hasCountry = agency.address['country'] != null && agency.address['country'].toString().isNotEmpty;

    return _buildSection(
      context,
      title: 'Adresse',
      icon: Icons.location_on_outlined,
      children: [
        if (hasStreet) _buildInfoRow('Rue:', agency.address['street']),
        if (hasCity) _buildInfoRow('Ville (adresse):', agency.address['city']),
        if (hasZipCode) _buildInfoRow('Code postal:', agency.address['zip_code']),
        if (hasCountry) _buildInfoRow('Pays:', agency.address['country']),
        if (!hasStreet && !hasCity && !hasZipCode && !hasCountry)
          const Text('Aucune adresse spécifiée', style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildContact(BuildContext context) {
    return _buildSection(
      context,
      title: 'Contact',
      icon: Icons.phone_outlined,
      children: [
        _buildInfoRow('Téléphone:', agency.phone),
        if (agency.email != null && agency.email!.isNotEmpty)
          _buildInfoRow('Email:', agency.email!),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return _buildSection(
      context,
      title: 'Actions',
      icon: Icons.settings,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Modifier'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: onEdit,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.directions_bus),
          label: const Text('Voir les bus'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Fermer le drawer
            _showAgencyBusesDialog(context, agency);
          },
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

  void _showAgencyBusesDialog(BuildContext context, AgencyModel agency) async {
    bool isLoading = true;
    List<BusModel> buses = [];
    
    try {
      buses = await context.read<BusRepository>().getBusesByAgency(agency.id);
      isLoading = false;
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus de l\'agence ${agency.name}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Code: ${agency.code}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Ajouter un bus',
                              onPressed: () {
                                Navigator.of(context).pop();
                                _createBusForAgency(context, agency.id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : buses.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.directions_bus_outlined,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun bus trouvé pour cette agence',
                                        style: Theme.of(context).textTheme.titleMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text('Ajouter un bus'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _createBusForAgency(context, agency.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: buses.length,
                                padding: const EdgeInsets.all(16),
                                itemBuilder: (context, index) {
                                  final bus = buses[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        child: Icon(
                                          _getBusTypeIcon(bus.type),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        '${bus.model} - ${bus.licensePlate}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text('${bus.type.displayName} - ${bus.capacity} places'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            tooltip: 'Modifier',
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              BusFormDialog.show(
                                                context: context,
                                                bus: bus,
                                                isEditing: true,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20),
                                            tooltip: 'Supprimer',
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _showDeleteBusConfirmation(context, bus);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des bus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createBusForAgency(BuildContext context, String agencyId) {
    BusFormDialog.show(
      context: context, 
      preselectedAgencyId: agencyId,
    );
  }

  void _showDeleteBusConfirmation(BuildContext context, BusModel bus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le bus ${bus.model} (${bus.licensePlate}) ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                context.read<BusBloc>().add(BusDelete(bus.id));
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  IconData _getBusTypeIcon(BusType type) {
    switch (type) {
      case BusType.MINIBUS_20P:
        return Icons.airport_shuttle;
      case BusType.VIP_32P:
        return Icons.airline_seat_recline_extra;
      case BusType.LUXE_50P:
        return Icons.directions_bus;
      case BusType.BUS_40P:
        return Icons.directions_bus_filled;
      case BusType.COACH_50P:
        return Icons.airport_shuttle_outlined;
      case BusType.DOUBLE_DECKER_70P:
        return Icons.tram;
      default:
        return Icons.directions_bus;
    }
  }
} 