import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/agency_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/responsive_layout.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/agency_form_dialog.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/agency_detail_drawer.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/bus_form_dialog.dart';

class AgencyListScreen extends StatefulWidget {
  const AgencyListScreen({Key? key}) : super(key: key);

  @override
  State<AgencyListScreen> createState() => _AgencyListScreenState();
}

class _AgencyListScreenState extends State<AgencyListScreen> {
  CityModel? _selectedCity;
  // Contrôleur pour le drawer de détails
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AgencyModel? _selectedAgency;
  Set<String> _expandedAgencies = {}; // Pour suivre les agences étendues
  Map<String, List<BusModel>> _agencyBuses = {}; // Cache des bus par agence
  Map<String, bool> _loadingBuses = {}; // États de chargement des bus
  
  @override
  void initState() {
    super.initState();
    context.read<AgencyBloc>().add(const AgencyLoadAll());
    context.read<CityBloc>().add(const CityLoadAll());
  }

  void _filterByCity(CityModel? city) {
    setState(() {
      _selectedCity = city;
    });

    if (city != null) {
      context.read<AgencyBloc>().add(AgencyLoadByCity(city.id));
    } else {
      context.read<AgencyBloc>().add(const AgencyLoadAll());
    }
  }

  // Méthode pour afficher les détails d'une agence dans un drawer
  void _showAgencyDetails(AgencyModel agency) {
    setState(() {
      _selectedAgency = agency;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // Méthode pour modifier une agence dans une boîte de dialogue
  void _editAgency(AgencyModel agency) {
    AgencyFormDialog.show(
      context: context,
      agency: agency,
      isEditing: true,
    );
  }

  // Méthode pour basculer l'état d'extension d'une agence
  void _toggleAgencyExpansion(AgencyModel agency) {
    setState(() {
      if (_expandedAgencies.contains(agency.id)) {
        _expandedAgencies.remove(agency.id);
      } else {
        _expandedAgencies.add(agency.id);
        _loadBusesForAgency(agency.id);
      }
    });
  }

  // Méthode pour charger les bus d'une agence
  Future<void> _loadBusesForAgency(String agencyId) async {
    if (_agencyBuses.containsKey(agencyId) && _agencyBuses[agencyId]!.isNotEmpty) {
      return; // Les bus sont déjà chargés
    }
    
    setState(() {
      _loadingBuses[agencyId] = true;
    });
    
    try {
      final buses = await context.read<BusRepository>().getBusesByAgency(agencyId);
      setState(() {
        _agencyBuses[agencyId] = buses;
        _loadingBuses[agencyId] = false;
      });
    } catch (e) {
      setState(() {
        _agencyBuses[agencyId] = [];
        _loadingBuses[agencyId] = false;
      });
    }
  }

  // Méthode pour créer un nouveau bus pour une agence
  void _createBusForAgency(String agencyId) {
    BusFormDialog.show(
      context: context, 
      preselectedAgencyId: agencyId,
    );
  }

  // Méthode pour rafraîchir les bus d'une agence
  Future<void> _refreshBusesForAgency(String agencyId) async {
    setState(() {
      _loadingBuses[agencyId] = true;
    });
    
    try {
      final buses = await context.read<BusRepository>().getBusesByAgency(agencyId);
      setState(() {
        _agencyBuses[agencyId] = buses;
        _loadingBuses[agencyId] = false;
      });
    } catch (e) {
      setState(() {
        _loadingBuses[agencyId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Gestion des Agences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une agence',
            onPressed: () {
              AgencyFormDialog.show(context: context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () {
              context.read<AgencyBloc>().add(const AgencyLoadAll());
            },
          ),
        ],
      ),
      // Drawer de détails à droite
      endDrawer: _selectedAgency != null 
          ? AgencyDetailDrawer(
              agency: _selectedAgency!,
              onEdit: () {
                Navigator.of(context).pop(); // Fermer le drawer
                _editAgency(_selectedAgency!);
              },
            )
          : null,
      body: Column(
        children: [
          // Filtre par ville
          _buildCityFilter(),
          
          // Liste des agences
          Expanded(
            child: BlocBuilder<AgencyBloc, AgencyState>(
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
                            context.read<AgencyBloc>().add(const AgencyLoadAll());
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.agencies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.business_outlined,
                          color: Colors.grey,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCity != null 
                            ? 'Aucune agence trouvée pour ${_selectedCity!.name}'
                            : 'Aucune agence trouvée',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            AgencyFormDialog.show(context: context);
                          },
                          child: const Text('Ajouter une agence'),
                        ),
                      ],
                    ),
                  );
                }

                return ResponsiveLayout(
                  mobile: _buildAgencyList(context, state.agencies, isMobile: true),
                  tablet: _buildAgencyList(context, state.agencies),
                  desktop: _buildAgencyTable(context, state.agencies),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrer par ville',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<CityBloc, CityState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state.isError) {
                    return const Text('Erreur lors du chargement des villes');
                  }

                  final cities = state.cities;
                  
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Option "Toutes les villes"
                        FilterChip(
                          label: const Text('Toutes les villes'),
                          selected: _selectedCity == null,
                          onSelected: (selected) {
                            if (selected) {
                              _filterByCity(null);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ...cities.map((city) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(city.name),
                              selected: _selectedCity?.id == city.id,
                              onSelected: (selected) {
                                if (selected) {
                                  _filterByCity(city);
                                } else if (_selectedCity?.id == city.id) {
                                  _filterByCity(null);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyList(BuildContext context, List<AgencyModel> agencies, {bool isMobile = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agencies.length,
      itemBuilder: (context, index) {
        final agency = agencies[index];
        final isExpanded = _expandedAgencies.contains(agency.id);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  agency.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code: ${agency.code}'),
                    Text('Téléphone: ${agency.phone}'),
                    FutureBuilder<CityModel>(
                      future: context.read<CityBloc>().state.cities.isNotEmpty 
                        ? Future.value(context.read<CityBloc>().state.cities.firstWhere((c) => c.id == agency.cityId, orElse: () => CityModel(id: '', code: '', name: 'Inconnu', province: '', isMain: false)))
                        : context.read<CityRepository>().getCityById(agency.cityId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Ville: Chargement...');
                        }
                        
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Ville: Non disponible');
                        }
                        
                        return Text('Ville: ${snapshot.data!.name}');
                      },
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      tooltip: isExpanded ? 'Masquer les bus' : 'Voir les bus',
                      onPressed: () => _toggleAgencyExpansion(agency),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Modifier',
                      onPressed: () => _editAgency(agency),
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
                onTap: () => _showAgencyDetails(agency),
              ),
              
              // Section extensible pour afficher les bus
              if (isExpanded)
                Container(
                  color: Colors.grey.shade50,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bus de cette agence',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Rafraîchir les bus',
                                  onPressed: () => _refreshBusesForAgency(agency.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Ajouter un bus',
                                  onPressed: () => _createBusForAgency(agency.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _loadingBuses[agency.id] == true
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _agencyBuses.containsKey(agency.id) && _agencyBuses[agency.id]!.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: Text('Aucun bus trouvé pour cette agence')),
                                )
                              : _buildBusList(context, agency.id),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgencyTable(BuildContext context, List<AgencyModel> agencies) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: PaginatedDataTable(
          header: const Text('Liste des Agences'),
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Ville')),
            DataColumn(label: Text('Adresse')),
            DataColumn(label: Text('Téléphone')),
            DataColumn(label: Text('Actions')),
          ],
          source: _AgencyDataSource(
            agencies,
            context,
            cityBloc: context.read<CityBloc>(),
            cityRepository: context.read<CityRepository>(),
            onView: _showAgencyDetails,
            onEdit: _editAgency,
            onDelete: (agency) => _showDeleteConfirmation(context, agency),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AgencyModel agency) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'agence ${agency.name} (${agency.code}) ?\n\nAttention: Tous les bus associés à cette agence seront également supprimés.',
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
                context.read<AgencyBloc>().add(AgencyDelete(agency.id));
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

  // Widget pour afficher la liste des bus d'une agence
  Widget _buildBusList(BuildContext context, String agencyId) {
    final buses = _agencyBuses[agencyId] ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: buses.length,
      itemBuilder: (context, index) {
        final bus = buses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
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
                  icon: const Icon(Icons.visibility, size: 20),
                  tooltip: 'Détails',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/buses/details',
                      arguments: bus.id,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Modifier',
                  onPressed: () {
                    BusFormDialog.show(
                      context: context,
                      bus: bus,
                      isEditing: true,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Icône correspondant au type de bus
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

// Source de données pour le tableau
class _AgencyDataSource extends DataTableSource {
  final List<AgencyModel> _agencies;
  final BuildContext _context;
  final CityBloc cityBloc;
  final CityRepository cityRepository;
  final Function(AgencyModel) onView;
  final Function(AgencyModel) onEdit;
  final Function(AgencyModel) onDelete;

  _AgencyDataSource(
    this._agencies,
    this._context, {
    required this.cityBloc,
    required this.cityRepository,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow getRow(int index) {
    final agency = _agencies[index];
    return DataRow(
      cells: [
        DataCell(Text(agency.code)),
        DataCell(Text(agency.name)),
        DataCell(
          FutureBuilder<CityModel>(
            future: cityBloc.state.cities.isNotEmpty
                ? Future.value(cityBloc.state.cities.firstWhere(
                    (c) => c.id == agency.cityId,
                    orElse: () => CityModel(id: '', code: '', name: 'Inconnu', province: '', isMain: false)))
                : cityRepository.getCityById(agency.cityId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Chargement...');
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Text('Non disponible');
              }

              return Text(snapshot.data!.name);
            },
          ),
        ),
        DataCell(Text(
          agency.address['street'] != null && agency.address['street'].isNotEmpty
            ? '${agency.address['street']}, ${agency.address['city'] ?? ''}'
            : 'Non spécifiée'
        )),
        DataCell(Text(agency.phone)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.directions_bus),
                tooltip: 'Voir les bus',
                onPressed: () {
                  Navigator.of(_context).pushNamed(
                    '/buses',
                    arguments: {'agencyId': agency.id},
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: 'Détails',
                onPressed: () => onView(agency),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
                onPressed: () => onEdit(agency),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Supprimer',
                onPressed: () => onDelete(agency),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _agencies.length;

  @override
  int get selectedRowCount => 0;
} 