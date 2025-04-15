import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/agency_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_event.dart';
import 'package:uuid/uuid.dart';

class BusFormDialog extends StatefulWidget {
  final BusModel? bus;
  final bool isEditing;
  final String? preselectedAgencyId;

  const BusFormDialog({
    Key? key,
    this.bus,
    this.isEditing = false,
    this.preselectedAgencyId,
  }) : super(key: key);

  @override
  State<BusFormDialog> createState() => _BusFormDialogState();

  /// Affiche la boîte de dialogue pour créer ou modifier un bus
  static Future<void> show({
    required BuildContext context,
    BusModel? bus,
    bool isEditing = false,
    String? preselectedAgencyId,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 600),
            child: BusFormDialog(
              bus: bus,
              isEditing: isEditing,
              preselectedAgencyId: preselectedAgencyId,
            ),
          ),
        );
      },
    );
  }
}

class _BusFormDialogState extends State<BusFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _agencyId;
  late String _licensePlate;
  late String _model;
  late BusType _type;
  late int _capacity;
  late double _baggageCapacityKg;
  late double _baggageVolumeM3;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _agencyId = widget.bus?.agencyId ?? widget.preselectedAgencyId ?? '';
    _licensePlate = widget.bus?.licensePlate ?? '';
    _model = widget.bus?.model ?? '';
    _type = widget.bus?.type ?? BusType.MINIBUS_20P;
    _capacity = widget.bus?.capacity ?? 20;
    _baggageCapacityKg = widget.bus?.baggageCapacityKg ?? 200.0;
    _baggageVolumeM3 = widget.bus?.baggageVolumeM3 ?? 2.0;

    // Charger les agences
    if (context.read<AgencyBloc>().state.agencies.isEmpty) {
      context.read<AgencyBloc>().add(const AgencyLoadAll());
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();

      setState(() {
        _isSubmitting = true;
      });

      if (widget.isEditing) {
        final updatedBus = widget.bus!.copyWith(
          agencyId: _agencyId,
          licensePlate: _licensePlate,
          model: _model,
          type: _type,
          capacity: _capacity,
          baggageCapacityKg: _baggageCapacityKg,
          baggageVolumeM3: _baggageVolumeM3,
        );
        context.read<BusBloc>().add(BusUpdate(updatedBus));
      } else {
        final newBus = BusModel(
          id: const Uuid().v4(),
          agencyId: _agencyId,
          licensePlate: _licensePlate,
          model: _model,
          type: _type,
          capacity: _capacity,
          baggageCapacityKg: _baggageCapacityKg,
          baggageVolumeM3: _baggageVolumeM3,
        );
        context.read<BusBloc>().add(BusCreate(newBus));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                widget.isEditing ? 'Modifier un Bus' : 'Ajouter un Bus',
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
                    // Sélection de l'agence
                    BlocBuilder<AgencyBloc, AgencyState>(
                      builder: (context, state) {
                        if (state.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state.isError) {
                          return const Center(
                            child: Text('Erreur lors du chargement des agences'),
                          );
                        }

                        if (state.agencies.isEmpty) {
                          return Card(
                            color: Colors.amber[100],
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Aucune agence disponible',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Veuillez d\'abord créer une agence avant d\'ajouter un bus.',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Si c'est la première fois qu'on charge les données et qu'on n'a pas d'agence sélectionnée
                        if (_agencyId.isEmpty && state.agencies.isNotEmpty) {
                          _agencyId = state.agencies.first.id;
                        }

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Agence',
                            border: OutlineInputBorder(),
                          ),
                          value: _agencyId.isNotEmpty && state.agencies.any((a) => a.id == _agencyId)
                              ? _agencyId
                              : state.agencies.first.id,
                          items: state.agencies.map((agency) {
                            return DropdownMenuItem<String>(
                              value: agency.id,
                              child: Text('${agency.name} (${agency.code})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _agencyId = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner une agence';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Immatriculation
                    TextFormField(
                      initialValue: _licensePlate,
                      decoration: const InputDecoration(
                        labelText: 'Immatriculation',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: ABC-123-XYZ',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer l\'immatriculation';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _licensePlate = value!.toUpperCase();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Modèle
                    TextFormField(
                      initialValue: _model,
                      decoration: const InputDecoration(
                        labelText: 'Modèle',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Mercedes Tourismo',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le modèle';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _model = value!;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type de bus
                    DropdownButtonFormField<BusType>(
                      decoration: const InputDecoration(
                        labelText: 'Type de Bus',
                        border: OutlineInputBorder(),
                      ),
                      value: _type,
                      items: BusType.values.map((type) {
                        return DropdownMenuItem<BusType>(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                            // Mettre à jour la capacité en fonction du type
                            switch (value) {
                              case BusType.MINIBUS_20P:
                                _capacity = 20;
                                break;
                              case BusType.VIP_32P:
                                _capacity = 32;
                                break;
                              case BusType.LUXE_50P:
                                _capacity = 50;
                                break;
                              case BusType.BUS_40P:
                                _capacity = 40;
                                break;
                              case BusType.COACH_50P:
                                _capacity = 50;
                                break;
                              case BusType.DOUBLE_DECKER_70P:
                                _capacity = 70;
                                break;
                            }
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un type de bus';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Capacité
                    TextFormField(
                      initialValue: _capacity.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Capacité (nombre de sièges)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer la capacité';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _capacity = int.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Capacité bagages (kg)
                    TextFormField(
                      initialValue: _baggageCapacityKg.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Capacité bagages (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer la capacité bagages en kg';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _baggageCapacityKg = double.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Volume bagages (m3)
                    TextFormField(
                      initialValue: _baggageVolumeM3.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Volume bagages (m³)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le volume bagages en m³';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _baggageVolumeM3 = double.parse(value!);
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
                  backgroundColor: Theme.of(context).primaryColor,
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