import 'package:flutter/material.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/bus_form_dialog.dart';

class BusDetailDrawer extends StatelessWidget {
  final BusModel bus;
  final VoidCallback? onEdit;

  const BusDetailDrawer({
    Key? key,
    required this.bus,
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
                  _buildCapacityInfo(context),
                  const SizedBox(height: 24),
                  _buildAgencyInfo(context),
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
                'Détails du Bus',
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
            bus.licensePlate,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
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
        _buildInfoRow('Modèle:', bus.model),
        _buildInfoRow('Type:', bus.type.displayName),
        _buildInfoRow('Immatriculation:', bus.licensePlate),
        _buildInfoRow('Date d\'ajout:', bus.createdAt != null 
            ? '${bus.createdAt!.day}/${bus.createdAt!.month}/${bus.createdAt!.year}'
            : 'Non spécifiée'),
      ],
    );
  }

  Widget _buildCapacityInfo(BuildContext context) {
    return _buildSection(
      context,
      title: 'Capacité',
      icon: Icons.event_seat,
      children: [
        _buildInfoRow('Nombre de places:', '${bus.capacity} sièges'),
        _buildInfoRow('Capacité bagages:', '${bus.baggageCapacityKg} kg'),
        _buildInfoRow('Volume bagages:', '${bus.baggageVolumeM3} m³'),
      ],
    );
  }

  Widget _buildAgencyInfo(BuildContext context) {
    return _buildSection(
      context,
      title: 'Agence',
      icon: Icons.business,
      children: [
        _buildInfoRow('Identifiant de l\'agence:', bus.agencyId),
        // Ici, vous pourriez ajouter plus d'informations sur l'agence si disponibles
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
          icon: const Icon(Icons.build),
          label: const Text('Maintenance'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () {
            // TODO: Navigate to maintenance
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
} 