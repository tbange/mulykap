import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/agency_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:uuid/uuid.dart';

class AgencyFormDialog extends StatefulWidget {
  final AgencyModel? agency;
  final bool isEditing;

  const AgencyFormDialog({
    Key? key,
    this.agency,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AgencyFormDialog> createState() => _AgencyFormDialogState();

  /// Affiche la boîte de dialogue pour créer ou modifier une agence
  static Future<void> show({
    required BuildContext context,
    AgencyModel? agency,
    bool isEditing = false,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 600),
            child: AgencyFormDialog(
              agency: agency,
              isEditing: isEditing,
            ),
          ),
        );
      },
    );
  }
}

class _AgencyFormDialogState extends State<AgencyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _code;
  String? _cityId;
  late Map<String, dynamic> _address;
  late String _phone;
  late String? _email;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _name = widget.agency?.name ?? '';
    _code = widget.agency?.code ?? 'AG-';
    _cityId = widget.agency?.cityId;
    _address = widget.agency?.address ?? {
      'street': '',
      'city': '',
      'zip_code': '',
      'country': 'RDC',
    };
    _phone = widget.agency?.phone ?? '';
    _email = widget.agency?.email;

    // Charger les villes
    if (context.read<CityBloc>().state.cities.isEmpty) {
      context.read<CityBloc>().add(const CityLoadAll());
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();

      if (_cityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une ville'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      if (widget.isEditing) {
        final updatedAgency = widget.agency!.copyWith(
          name: _name,
          code: _code,
          cityId: _cityId!,
          address: _address,
          phone: _phone,
          email: _email,
        );
        context.read<AgencyBloc>().add(AgencyUpdate(updatedAgency));
      } else {
        final newAgency = AgencyModel(
          id: const Uuid().v4(),
          name: _name,
          code: _code,
          cityId: _cityId!,
          address: _address,
          phone: _phone,
          email: _email,
        );
        context.read<AgencyBloc>().add(AgencyCreate(newAgency));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer la couleur principale de l'application
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la boîte de dialogue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEditing ? 'Modifier une Agence' : 'Ajouter une Agence',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          
          // Formulaire
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de l'agence
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'agence',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Transport Express',
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
                    const SizedBox(height: 16),

                    // Code de l'agence
                    TextFormField(
                      initialValue: _code,
                      decoration: const InputDecoration(
                        labelText: 'Code (format AG-XXX requis)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: AG-EXP',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le code de l\'agence';
                        }
                        if (!RegExp(r'^AG-[A-Z0-9]{3}$').hasMatch(value)) {
                          return 'Format AG-XXX requis (XXX = 3 caractères)';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _code = value!.toUpperCase();
                      },
                    ),
                    const SizedBox(height: 16),

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
                                ],
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Ville',
                            border: OutlineInputBorder(),
                          ),
                          value: _cityId != null && state.cities.any((c) => c.id == _cityId)
                              ? _cityId
                              : null,
                          hint: const Text('Sélectionnez une ville'),
                          items: state.cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city.id,
                              child: Text('${city.name} (${city.province})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _cityId = value;
                            });
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

                    // Adresse - Rue
                    TextFormField(
                      initialValue: _address['street'] as String? ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Adresse (rue)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 123 Avenue Principale',
                      ),
                      onSaved: (value) {
                        _address['street'] = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Adresse - Ville
                    TextFormField(
                      initialValue: _address['city'] as String? ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Adresse (ville/quartier)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Quartier Commercial',
                      ),
                      onSaved: (value) {
                        _address['city'] = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Adresse - Code postal
                    TextFormField(
                      initialValue: _address['zip_code'] as String? ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Code postal',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 12345',
                      ),
                      onSaved: (value) {
                        _address['zip_code'] = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Adresse - Pays
                    TextFormField(
                      initialValue: _address['country'] as String? ?? 'RDC',
                      decoration: const InputDecoration(
                        labelText: 'Pays',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: RDC',
                      ),
                      onSaved: (value) {
                        _address['country'] = value ?? 'RDC';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      initialValue: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: +243 123 456 789',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro de téléphone';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _phone = value!;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      initialValue: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email (optionnel)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: contact@agence.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (value) {
                        _email = value!.isEmpty ? null : value;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // Utiliser la couleur principale
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Mettre à jour' : 'Ajouter',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 