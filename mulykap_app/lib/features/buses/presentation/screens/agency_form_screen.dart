import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/agency_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:uuid/uuid.dart';

class AgencyFormScreen extends StatefulWidget {
  final AgencyModel? agency;
  final bool isEditing;

  const AgencyFormScreen({
    Key? key,
    this.agency,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AgencyFormScreen> createState() => _AgencyFormScreenState();
}

class _AgencyFormScreenState extends State<AgencyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _cityId;
  late String _code;
  late String _name;
  late Map<String, dynamic> _address;
  late String _phone;
  late String? _email;
  bool _isSubmitting = false;

  // Contrôleurs pour les champs d'adresse
  final _streetController = TextEditingController();
  final _cityNameController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cityId = widget.agency?.cityId ?? '';
    _code = widget.agency?.code ?? '';
    _name = widget.agency?.name ?? '';
    _phone = widget.agency?.phone ?? '';
    _email = widget.agency?.email;
    _address = widget.agency?.address ?? {'street': '', 'city': '', 'zip_code': '', 'country': 'RDC'};
    
    // Initialiser les contrôleurs d'adresse
    _streetController.text = _address['street'] ?? '';
    _cityNameController.text = _address['city'] ?? '';
    _zipCodeController.text = _address['zip_code'] ?? '';
    _countryController.text = _address['country'] ?? 'RDC';
    _phoneController.text = _phone;
    _emailController.text = _email ?? '';

    // Charger les villes
    if (context.read<CityBloc>().state.cities.isEmpty) {
      context.read<CityBloc>().add(const CityLoadAll());
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityNameController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();

      // Mettre à jour l'adresse avec les valeurs actuelles des contrôleurs
      _address = {
        'street': _streetController.text,
        'city': _cityNameController.text,
        'zip_code': _zipCodeController.text,
        'country': _countryController.text,
      };
      
      _phone = _phoneController.text;
      _email = _emailController.text.isEmpty ? null : _emailController.text;

      setState(() {
        _isSubmitting = true;
      });

      if (widget.isEditing) {
        final updatedAgency = widget.agency!.copyWith(
          cityId: _cityId,
          code: _code,
          name: _name,
          address: _address,
          phone: _phone,
          email: _email,
        );
        context.read<AgencyBloc>().add(AgencyUpdate(updatedAgency));
      } else {
        final newAgency = AgencyModel(
          id: const Uuid().v4(),
          cityId: _cityId,
          code: _code,
          name: _name,
          address: _address,
          phone: _phone,
          email: _email,
        );
        context.read<AgencyBloc>().add(AgencyCreate(newAgency));
      }

      // Retourner à l'écran précédent après soumission
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier une Agence' : 'Ajouter une Agence'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection de la ville
              BlocBuilder<CityBloc, CityState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state.isError) {
                    return const Center(
                      child: Text('Erreur lors du chargement des villes'),
                    );
                  }

                  if (state.cities.isEmpty) {
                    return Card(
                      color: Colors.amber[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aucune ville disponible',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Veuillez d\'abord créer une ville avant d\'ajouter une agence.',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                // Naviguer vers l'écran d'ajout de ville
                                // Normalement, vous auriez un écran de gestion des villes
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fonctionnalité à implémenter: Ajouter une ville'),
                                  ),
                                );
                              },
                              child: const Text('Créer une Ville'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Si c'est la première fois qu'on charge les données et qu'on n'a pas de ville sélectionnée
                  if (_cityId.isEmpty && state.cities.isNotEmpty) {
                    _cityId = state.cities.first.id;
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      border: OutlineInputBorder(),
                    ),
                    value: _cityId.isNotEmpty && state.cities.any((c) => c.id == _cityId)
                        ? _cityId
                        : state.cities.first.id,
                    items: state.cities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city.id,
                        child: Text('${city.name} (${city.province})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _cityId = value;
                          
                          // Mettre à jour le champ de ville dans l'adresse avec le nom de la ville sélectionnée
                          final selectedCity = state.cities.firstWhere((c) => c.id == value);
                          _cityNameController.text = selectedCity.name;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une ville';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Code de l'agence
              TextFormField(
                initialValue: _code,
                decoration: const InputDecoration(
                  labelText: 'Code de l\'agence',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: KIN-01',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le code de l\'agence';
                  }
                  return null;
                },
                onSaved: (value) {
                  _code = value!.toUpperCase();
                },
              ),
              const SizedBox(height: 16),

              // Nom de l'agence
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'agence',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Agence Principale de Kinshasa',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de l\'agence';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 24),

              // Section Adresse
              const Text(
                'Adresse',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Rue
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Rue',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 123 Avenue de la Libération',
                ),
                validator: (value) {
                  // La rue est optionnelle
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ville (dans l'adresse)
              TextFormField(
                controller: _cityNameController,
                decoration: const InputDecoration(
                  labelText: 'Ville (adresse)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Kinshasa',
                ),
                enabled: false, // Désactivé car synchronisé avec la ville sélectionnée
              ),
              const SizedBox(height: 16),

              // Code postal
              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code postal',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 00243',
                ),
                validator: (value) {
                  // Le code postal est optionnel
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pays
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: RDC',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le pays';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Champ Téléphone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une adresse email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Veuillez saisir une adresse email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : Text(
                          widget.isEditing ? 'Mettre à jour' : 'Ajouter',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 