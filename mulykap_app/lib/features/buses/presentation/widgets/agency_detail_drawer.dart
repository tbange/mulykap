import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';

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
            Navigator.of(context).pushNamed(
              '/buses',
              arguments: {'agencyId': agency.id},
            );
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