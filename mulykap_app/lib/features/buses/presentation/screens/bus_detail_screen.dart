import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mulykap_app/features/buses/data/repositories/agency_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_event.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_state.dart';

class BusDetailScreen extends StatefulWidget {
  final String busId;

  const BusDetailScreen({
    Key? key,
    required this.busId,
  }) : super(key: key);

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  AgencyModel? _agency;
  bool _isLoadingAgency = false;

  @override
  void initState() {
    super.initState();
    context.read<BusBloc>().add(BusLoad(widget.busId));
  }

  Future<void> _loadAgency(String agencyId) async {
    if (_isLoadingAgency) return;

    setState(() {
      _isLoadingAgency = true;
    });

    try {
      final agencyRepo = context.read<AgencyRepository>();
      final agency = await agencyRepo.getAgencyById(agencyId);
      
      setState(() {
        _agency = agency;
        _isLoadingAgency = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAgency = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement de l\'agence: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Bus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () {
              final state = context.read<BusBloc>().state;
              if (state.selectedBus != null) {
                Navigator.of(context).pushNamed(
                  '/buses/edit',
                  arguments: state.selectedBus,
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<BusBloc, BusState>(
        listener: (context, state) {
          // Charger les informations de l'agence si le bus est chargé
          if (state.selectedBus != null && (_agency == null || _agency!.id != state.selectedBus!.agencyId)) {
            _loadAgency(state.selectedBus!.agencyId);
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.error}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BusBloc>().add(BusLoad(widget.busId));
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final bus = state.selectedBus;
          if (bus == null) {
            return const Center(
              child: Text('Bus non trouvé'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec les informations principales
                _buildHeader(context, bus),
                const SizedBox(height: 24),

                // Détails du bus
                _buildDetailsCard(context, bus),
                const SizedBox(height: 16),

                // Informations sur l'agence
                _buildAgencyCard(context),
                const SizedBox(height: 16),

                // Actions disponibles
                _buildActionsCard(context, bus),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BusModel bus) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône du bus
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getBusTypeIcon(bus.type),
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informations principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.model,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Immatriculation: ${bus.licensePlate}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBusTypeColor(bus.type),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      bus.type.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, BusModel bus) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Caractéristiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context, 
              'Capacité', 
              '${bus.capacity} sièges',
              Icons.event_seat,
            ),
            _buildDetailRow(
              context, 
              'Capacité bagages', 
              '${bus.baggageCapacityKg} kg',
              Icons.luggage,
            ),
            _buildDetailRow(
              context, 
              'Volume bagages', 
              '${bus.baggageVolumeM3} m³',
              Icons.business_center,
            ),
            _buildDetailRow(
              context, 
              'Créé le', 
              bus.createdAt != null ? dateFormat.format(bus.createdAt!) : 'Non spécifié',
              Icons.calendar_today,
            ),
            _buildDetailRow(
              context, 
              'Dernière mise à jour', 
              bus.updatedAt != null ? dateFormat.format(bus.updatedAt!) : 'Non spécifié',
              Icons.update,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyCard(BuildContext context) {
    if (_isLoadingAgency) {
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

    if (_agency == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Informations sur l\'agence non disponibles'),
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
              'Agence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context, 
              'Nom', 
              _agency!.name,
              Icons.business,
            ),
            _buildDetailRow(
              context, 
              'Code', 
              _agency!.code,
              Icons.code,
            ),
            _buildDetailRow(
              context, 
              'Adresse', 
              _formatAddress(_agency!.address),
              Icons.location_on,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, BusModel bus) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionButton(
                  icon: Icons.edit,
                  label: 'Modifier',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/buses/edit',
                      arguments: bus,
                    );
                  },
                ),
                ActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer',
                  onPressed: () {
                    _showDeleteConfirmation(context, bus);
                  },
                  color: Colors.red,
                ),
                ActionButton(
                  icon: Icons.build,
                  label: 'Maintenance',
                  onPressed: () {
                    // TODO: Naviguer vers l'historique de maintenance
                  },
                ),
                ActionButton(
                  icon: Icons.map,
                  label: 'Voyages',
                  onPressed: () {
                    // TODO: Naviguer vers les voyages du bus
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    {bool isLast = false}
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
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
    final zipCode = address['zip_code'] ?? '';
    final country = address['country'] ?? '';

    if (street.isEmpty && city.isEmpty && zipCode.isEmpty && country.isEmpty) {
      return 'Adresse non spécifiée';
    }

    final List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) {
      if (zipCode.isNotEmpty) {
        parts.add('$zipCode $city');
      } else {
        parts.add(city);
      }
    }
    if (country.isNotEmpty) parts.add(country);

    return parts.join(', ');
  }

  void _showDeleteConfirmation(BuildContext context, BusModel bus) {
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
                Navigator.of(context).pop(); // Retour à la liste des bus
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

  Color _getBusTypeColor(BusType type) {
    switch (type) {
      case BusType.MINIBUS_20P:
        return Colors.blue;
      case BusType.VIP_32P:
        return Colors.purple;
      case BusType.LUXE_50P:
        return Colors.green;
      case BusType.BUS_40P:
        return Colors.orange;
      case BusType.COACH_50P:
        return Colors.teal;
      case BusType.DOUBLE_DECKER_70P:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color != null ? Colors.white : null,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
} 