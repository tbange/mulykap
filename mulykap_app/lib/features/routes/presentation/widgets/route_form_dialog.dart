import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/presentation/bloc/route_bloc.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:uuid/uuid.dart';

class RouteFormDialog extends StatefulWidget {
  final RouteModel? route;
  final bool isEditing;

  const RouteFormDialog({
    Key? key,
    this.route,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<RouteFormDialog> createState() => _RouteFormDialogState();

  /// Affiche la boîte de dialogue pour créer ou modifier un itinéraire
  static Future<void> show({
    required BuildContext context,
    RouteModel? route,
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
            child: RouteFormDialog(
              route: route,
              isEditing: isEditing,
            ),
          ),
        );
      },
    );
  }
}

class _RouteFormDialogState extends State<RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  List<CityModel> _cities = [];
  bool _isLoadingCities = false;
  bool _isSubmitting = false;
  
  late String _departureCityId;
  late String _arrivalCityId;
  late double _distanceKm;
  late int _durationHours;
  late int _durationMinutes;

  @override
  void initState() {
    super.initState();
    _departureCityId = widget.route?.departureCityId ?? '';
    _arrivalCityId = widget.route?.arrivalCityId ?? '';
    _distanceKm = widget.route?.distanceKm ?? 0.0;
    
    // Initialiser la durée
    if (widget.route != null) {
      _durationHours = widget.route!.estimatedDuration.inHours;
      _durationMinutes = widget.route!.estimatedDuration.inMinutes % 60;
    } else {
      _durationHours = 0;
      _durationMinutes = 0;
    }
    
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final cityRepository = RepositoryProvider.of<CityRepository>(context);
      final cities = await cityRepository.getAllCities();
      
      if (mounted) {
        setState(() {
          _cities = cities;
          _isLoadingCities = false;
          
          // Définir les valeurs par défaut si pas encore sélectionnées
          if (_departureCityId.isEmpty && cities.isNotEmpty) {
            _departureCityId = cities.first.id;
          }
          if (_arrivalCityId.isEmpty && cities.length > 1) {
            _arrivalCityId = cities[1].id;
          } else if (_arrivalCityId.isEmpty && cities.isNotEmpty) {
            _arrivalCityId = cities.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des villes: $e')),
        );
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      
      // Vérifier que la ville de départ et d'arrivée sont différentes
      if (_departureCityId == _arrivalCityId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).sameCityError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      // Calculer la durée totale en minutes
      final durationMinutes = (_durationHours * 60) + _durationMinutes;
      final duration = Duration(minutes: durationMinutes);

      if (widget.isEditing && widget.route != null) {
        final updatedRoute = widget.route!.copyWith(
          departureCityId: _departureCityId,
          arrivalCityId: _arrivalCityId,
          distanceKm: _distanceKm,
          estimatedDuration: duration,
        );
        context.read<RouteBloc>().add(UpdateRoute(route: updatedRoute));
      } else {
        final newRoute = RouteModel(
          id: const Uuid().v4(),
          departureCityId: _departureCityId,
          arrivalCityId: _arrivalCityId,
          distanceKm: _distanceKm,
          estimatedDuration: duration,
        );
        context.read<RouteBloc>().add(CreateRoute(route: newRoute));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
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
                widget.isEditing ? l10n.editRoute : l10n.newRoute,
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
            child: _isLoadingCities 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_cities.isEmpty)
                            Card(
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
                                      'Veuillez d\'abord créer des villes avant d\'ajouter un itinéraire.',
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                // Ville de départ
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: l10n.departureCity,
                                    border: const OutlineInputBorder(),
                                  ),
                                  value: _departureCityId.isNotEmpty && _cities.any((c) => c.id == _departureCityId)
                                      ? _departureCityId
                                      : _cities.first.id,
                                  items: _cities.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city.id,
                                      child: Text(city.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _departureCityId = value;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Ville d'arrivée
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: l10n.arrivalCity,
                                    border: const OutlineInputBorder(),
                                  ),
                                  value: _arrivalCityId.isNotEmpty && _cities.any((c) => c.id == _arrivalCityId)
                                      ? _arrivalCityId
                                      : _cities.first.id,
                                  items: _cities.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city.id,
                                      child: Text(city.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _arrivalCityId = value;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Distance
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: l10n.distanceKm,
                                    border: const OutlineInputBorder(),
                                  ),
                                  initialValue: _distanceKm.toString(),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      _distanceKm = double.tryParse(value) ?? 0.0;
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.requiredField;
                                    }
                                    final distance = double.tryParse(value);
                                    if (distance == null) {
                                      return l10n.invalidNumber;
                                    }
                                    if (distance <= 0) {
                                      return l10n.positiveNumberRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Durée estimée
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: l10n.hours,
                                          border: const OutlineInputBorder(),
                                        ),
                                        initialValue: _durationHours.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        onChanged: (value) {
                                          if (value.isNotEmpty) {
                                            _durationHours = int.tryParse(value) ?? 0;
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return null; // Heures peuvent être 0
                                          }
                                          final hours = int.tryParse(value);
                                          if (hours == null) {
                                            return l10n.invalidNumber;
                                          }
                                          if (hours < 0) {
                                            return l10n.positiveNumberRequired;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: l10n.minutes,
                                          border: const OutlineInputBorder(),
                                        ),
                                        initialValue: _durationMinutes.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        onChanged: (value) {
                                          if (value.isNotEmpty) {
                                            _durationMinutes = int.tryParse(value) ?? 0;
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return l10n.requiredField;
                                          }
                                          final minutes = int.tryParse(value);
                                          if (minutes == null) {
                                            return l10n.invalidNumber;
                                          }
                                          if (minutes < 0) {
                                            return l10n.positiveNumberRequired;
                                          }
                                          if (minutes > 59) {
                                            return l10n.invalidMinutes;
                                          }
                                          if (minutes == 0 && _durationHours == 0) {
                                            return l10n.durationRequired;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),
                          
                          // Boutons d'action
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                  child: Text(l10n.cancel),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(widget.isEditing ? l10n.saveChanges : l10n.createRoute),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 