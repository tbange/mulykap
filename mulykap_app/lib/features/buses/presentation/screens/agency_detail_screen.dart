import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/agency_bloc.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/responsive_layout.dart';

class AgencyDetailScreen extends StatefulWidget {
  final String agencyId;

  const AgencyDetailScreen({
    Key? key,
    required this.agencyId,
  }) : super(key: key);

  @override
  State<AgencyDetailScreen> createState() => _AgencyDetailScreenState();
}

class _AgencyDetailScreenState extends State<AgencyDetailScreen> {
  CityModel? _city;
  List<BusModel> _buses = [];
  bool _isLoadingCity = false;
  bool _isLoadingBuses = false;

  @override
  void initState() {
    super.initState();
    context.read<AgencyBloc>().add(AgencyLoad(widget.agencyId));
  }

  Future<void> _loadCity(String cityId) async {
    if (_isLoadingCity) return;

    setState(() {
      _isLoadingCity = true;
    });

    try {
      final cityRepo = context.read<CityRepository>();
      final city = await cityRepo.getCityById(cityId);
      
      setState(() {
        _city = city;
        _isLoadingCity = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCity = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement de la ville: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadBuses(String agencyId) async {
    if (_isLoadingBuses) return;

    setState(() {
      _isLoadingBuses = true;
    });

    try {
      final busRepo = context.read<BusRepository>();
      final buses = await busRepo.getBusesByAgency(agencyId);
      
      setState(() {
        _buses = buses;
        _isLoadingBuses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBuses = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des bus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, AgencyModel agency) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer l\'agence "${agency.name}" ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AgencyBloc>().add(AgencyDelete(agency.id));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'Agence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () {
              final state = context.read<AgencyBloc>().state;
              if (state.selectedAgency != null) {
                Navigator.of(context).pushNamed(
                  '/agencies/edit',
                  arguments: state.selectedAgency,
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<AgencyBloc, AgencyState>(
        listener: (context, state) {
          if (state.status == AgencyStatus.loaded && state.selectedAgency != null) {
            if (_city == null || _city!.id != state.selectedAgency!.cityId) {
              _loadCity(state.selectedAgency!.cityId);
            }
            if (_buses.isEmpty) {
              _loadBuses(state.selectedAgency!.id);
            }
          }
        },
        builder: (context, state) {
          if (state.status == AgencyStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == AgencyStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erreur: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AgencyBloc>().add(AgencyLoad(widget.agencyId));
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state.selectedAgency == null) {
            return const Center(
              child: Text('Agence non trouvée'),
            );
          }

          final agency = state.selectedAgency!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(context, agency),
              tablet: _buildTabletLayout(context, agency),
              desktop: _buildTabletLayout(context, agency),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(
            '/buses/add',
            arguments: {'agencyId': widget.agencyId},
          );
        },
        tooltip: 'Ajouter un bus',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AgencyModel agency) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAgencyDetailsCard(context, agency),
          const SizedBox(height: 16),
          _buildCityCard(context),
          const SizedBox(height: 16),
          _buildBusesCard(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, AgencyModel agency) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildAgencyDetailsCard(context, agency),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildCityCard(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBusesCard(context),
        ],
      ),
    );
  }

  Widget _buildAgencyDetailsCard(BuildContext context, AgencyModel agency) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Informations de l\'Agence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Supprimer',
                  onPressed: () {
                    _showDeleteConfirmation(context, agency);
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(
              context, 
              'Nom', 
              agency.name,
              Icons.business,
            ),
            _buildDetailRow(
              context, 
              'Code', 
              agency.code,
              Icons.code,
            ),
            _buildDetailRow(
              context, 
              'Adresse', 
              _formatAddress(agency.address),
              Icons.location_on,
            ),
            _buildDetailRow(
              context, 
              'Créé le', 
              agency.createdAt != null ? dateFormat.format(agency.createdAt!) : 'Non spécifié',
              Icons.calendar_today,
            ),
            _buildDetailRow(
              context, 
              'Dernière mise à jour', 
              agency.updatedAt != null ? dateFormat.format(agency.updatedAt!) : 'Non spécifié',
              Icons.update,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityCard(BuildContext context) {
    if (_isLoadingCity) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_city == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ville',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Informations sur la ville non disponibles'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ville',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(
              context, 
              'Nom', 
              _city!.name,
              Icons.location_city,
            ),
            _buildDetailRow(
              context, 
              'Code postal', 
              _city!.postalCode ?? 'Non spécifié',
              Icons.local_post_office,
            ),
            _buildDetailRow(
              context, 
              'Pays', 
              _city!.country ?? 'Non spécifié',
              Icons.flag,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusesCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bus de l\'Agence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un bus'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/buses/add',
                      arguments: {'agencyId': widget.agencyId},
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_isLoadingBuses)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_buses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aucun bus trouvé pour cette agence'),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildBusList(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusList(BuildContext context) {
    return ResponsiveLayout(
      mobile: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _buses.length,
        itemBuilder: (context, index) {
          final bus = _buses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text(bus.licensePlate),
              subtitle: Text('${bus.model} - ${_getBusTypeLabel(bus.type)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    tooltip: 'Détails',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/buses/details',
                        arguments: bus.id,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Modifier',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/buses/edit',
                        arguments: bus,
                      );
                    },
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/buses/details',
                  arguments: bus.id,
                );
              },
            ),
          );
        },
      ),
      tablet: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Immatriculation')),
            DataColumn(label: Text('Modèle')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Capacité')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _buses.map((bus) {
            return DataRow(
              cells: [
                DataCell(Text(bus.licensePlate)),
                DataCell(Text(bus.model)),
                DataCell(Text(_getBusTypeLabel(bus.type))),
                DataCell(Text('${bus.capacity} places')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: 'Détails',
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/buses/details',
                            arguments: bus.id,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Modifier',
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/buses/edit',
                            arguments: bus,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      desktop: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Immatriculation')),
            DataColumn(label: Text('Modèle')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Capacité')),
            DataColumn(label: Text('Capacité bagages')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _buses.map((bus) {
            return DataRow(
              cells: [
                DataCell(Text(bus.licensePlate)),
                DataCell(Text(bus.model)),
                DataCell(Text(_getBusTypeLabel(bus.type))),
                DataCell(Text('${bus.capacity} places')),
                DataCell(Text('${bus.baggageCapacityKg} kg / ${bus.baggageVolumeM3} m³')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: 'Détails',
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/buses/details',
                            arguments: bus.id,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Modifier',
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/buses/edit',
                            arguments: bus,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final postalCode = address['postal_code'] ?? '';
    final country = address['country'] ?? '';
    
    return '$street, $postalCode $city, $country';
  }

  String _getBusTypeLabel(BusType type) {
    switch (type) {
      case BusType.MINIBUS_20P:
        return 'Minibus (20 places)';
      case BusType.VIP_32P:
        return 'VIP (32 places)';
      case BusType.LUXE_50P:
        return 'Luxe (50 places)';
      case BusType.BUS_40P:
        return 'Bus (40 places)';
      case BusType.COACH_50P:
        return 'Autocar (50 places)';
      case BusType.DOUBLE_DECKER_70P:
        return 'Bus à impériale (70 places)';
      default:
        return 'Inconnu';
    }
  }
} 