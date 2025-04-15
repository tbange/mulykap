import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/responsive_layout.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/city_form_dialog.dart';
import 'package:intl/intl.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({Key? key}) : super(key: key);

  @override
  State<CityListScreen> createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedProvince = '';
  List<String> _provinces = [];
  List<CityModel> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    context.read<CityBloc>().add(const CityLoadAll());
    _provinces = [];
    _filteredCities = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final state = context.read<CityBloc>().state;
    if (state.cities.isNotEmpty && _filteredCities.isEmpty) {
      _filterCities(state.cities);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities(List<CityModel> cities) {
    final searchQuery = _searchController.text.toLowerCase();
    
    // Extraire toutes les provinces - mais seulement s'il faut reconstruire la liste
    if (_provinces.isEmpty && cities.isNotEmpty) {
      final Set<String> uniqueProvinces = cities.map((city) => city.province).toSet();
      List<String> provincesList = uniqueProvinces.toList()..sort();
      provincesList.insert(0, 'Toutes les provinces');
      
      // Utiliser une liste locale pour ne pas déclencher setState pendant le build
      _provinces = provincesList;
    }

    // Filtrer les villes
    List<CityModel> filtered = cities.where((city) {
      final matchesSearch = 
          city.name.toLowerCase().contains(searchQuery) ||
          city.code.toLowerCase().contains(searchQuery) ||
          city.province.toLowerCase().contains(searchQuery);
          
      final matchesProvince = _selectedProvince.isEmpty || 
          _selectedProvince == 'Toutes les provinces' || 
          city.province == _selectedProvince;
          
      return matchesSearch && matchesProvince;
    }).toList();
    
    // Mise à jour de l'état une seule fois avec la liste déjà filtrée
    setState(() {
      _filteredCities = filtered;
    });
  }

  void _showAddEditCityDialog([CityModel? city]) {
    CityFormDialog.show(
      context: context,
      city: city,
      isEditing: city != null,
    );
  }

  void _showDeleteConfirmation(BuildContext context, CityModel city) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer la ville "${city.name}" (${city.code}) ?\n\nCette action est irréversible et supprimera tous les itinéraires associés à cette ville.',
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
                context.read<CityBloc>().add(CityDelete(city.id));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Villes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une ville',
            onPressed: () {
              _showAddEditCityDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () {
              context.read<CityBloc>().add(const CityLoadAll());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Rechercher',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        hintText: 'Rechercher par nom, code ou province...',
                      ),
                      onChanged: (_) {
                        _filterCities(context.read<CityBloc>().state.cities);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Filtrer par province',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<CityBloc, CityState>(
                      builder: (context, state) {
                        if (state.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (_provinces.isEmpty && state.cities.isNotEmpty) {
                          _filterCities(state.cities);
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _provinces.map((province) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(province),
                                  selected: _selectedProvince == province,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedProvince = selected ? province : '';
                                      _filterCities(state.cities);
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Liste des villes
          Expanded(
            child: BlocConsumer<CityBloc, CityState>(
              listener: (context, state) {
                if (state.cities.isNotEmpty) {
                  // Appliquer le filtre uniquement lorsque les villes changent
                  // et ne pas le faire pendant le build
                  Future.microtask(() => _filterCities(state.cities));
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
                            context.read<CityBloc>().add(const CityLoadAll());
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                // Initialiser _filteredCities si nécessaire au lieu d'utiliser le listener
                if (_filteredCities.isEmpty && state.cities.isNotEmpty && !state.isLoading) {
                  // Utiliser une future microtask pour éviter setState pendant le build
                  Future.microtask(() => _filterCities(state.cities));
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_filteredCities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_city_outlined,
                          color: Colors.grey,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty || _selectedProvince.isNotEmpty
                              ? 'Aucune ville ne correspond à votre recherche'
                              : 'Aucune ville trouvée',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (_searchController.text.isEmpty && _selectedProvince.isEmpty)
                          ElevatedButton(
                            onPressed: () {
                              _showAddEditCityDialog();
                            },
                            child: const Text('Ajouter une ville'),
                          ),
                      ],
                    ),
                  );
                }

                return ResponsiveLayout(
                  mobile: _buildCityList(context, _filteredCities),
                  tablet: _buildCityList(context, _filteredCities),
                  desktop: _buildCityTable(context, _filteredCities),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditCityDialog();
        },
        tooltip: 'Ajouter une ville',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCityList(BuildContext context, List<CityModel> cities) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: city.isMain ? Colors.blue : Colors.grey,
              child: const Icon(
                Icons.location_city,
                color: Colors.white,
              ),
            ),
            title: Text(
              city.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${city.code}'),
                Text('Province: ${city.province}'),
                if (city.postalCode != null && city.postalCode!.isNotEmpty)
                  Text('Code postal: ${city.postalCode}'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (city.isMain)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: const Text('Principale', style: TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: Colors.blue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier',
                  onPressed: () {
                    _showAddEditCityDialog(city);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Supprimer',
                  onPressed: () {
                    _showDeleteConfirmation(context, city);
                  },
                ),
              ],
            ),
            onTap: () {
              _showAddEditCityDialog(city);
            },
          ),
        );
      },
    );
  }

  Widget _buildCityTable(BuildContext context, List<CityModel> cities) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Container(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Province')),
                  DataColumn(label: Text('Pays')),
                  DataColumn(label: Text('Principale')),
                  DataColumn(label: Text('Date de création')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: cities.map((city) {
                  return DataRow(
                    cells: [
                      DataCell(Text(city.code)),
                      DataCell(Text(city.name)),
                      DataCell(Text(city.province)),
                      DataCell(Text(city.country ?? 'Non spécifié')),
                      DataCell(
                        city.isMain
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.cancel, color: Colors.grey),
                      ),
                      DataCell(Text(city.createdAt != null ? dateFormat.format(city.createdAt!) : 'N/A')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Modifier',
                              onPressed: () {
                                _showAddEditCityDialog(city);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Supprimer',
                              onPressed: () {
                                _showDeleteConfirmation(context, city);
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
          ),
        ),
      ),
    );
  }
} 