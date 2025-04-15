import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/common/presentation/widgets/app_loading_indicator.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/presentation/bloc/route_bloc.dart';
import 'package:mulykap_app/features/shared/presentation/widgets/app_error_widget.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:uuid/uuid.dart';

class RouteFormScreen extends StatefulWidget {
  final String? routeId;

  const RouteFormScreen({Key? key, this.routeId}) : super(key: key);

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  List<CityModel> _cities = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String? _departureCityId;
  String? _arrivalCityId;
  RouteModel? _existingRoute;
  
  late CityRepository _cityRepository;
  late RouteBloc _routeBloc;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    try {
      _cityRepository = context.read<CityRepository>();
      _routeBloc = context.read<RouteBloc>();
      _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur d'initialisation: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les villes
      final cities = await _cityRepository.getAllCities();
      
      setState(() {
        _cities = cities;
      });

      // Si c'est une modification, charger les détails de l'itinéraire
      if (widget.routeId != null) {
        // Écouter l'état pour récupérer l'itinéraire
        _subscription?.cancel();
        _subscription = _routeBloc.stream.listen((state) {
          if (state is RouteLoaded) {
            try {
              final route = state.routes.firstWhere(
                (r) => r.id == widget.routeId,
                orElse: () => throw Exception('Itinéraire non trouvé'),
              );
              _setRouteData(route);
            } catch (e) {
              setState(() {
                _errorMessage = e.toString();
                _isLoading = false;
              });
            }
            _subscription?.cancel();
          } else if (state is RouteError) {
            setState(() {
              _errorMessage = state.message;
              _isLoading = false;
            });
            _subscription?.cancel();
          }
        });
        
        // Demander le chargement des itinéraires
        _routeBloc.add(const LoadRoutes());
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setRouteData(RouteModel route) {
    _existingRoute = route;
    _departureCityId = route.departureCityId;
    _arrivalCityId = route.arrivalCityId;
    _distanceController.text = route.distanceKm.toString();
    _hoursController.text = route.estimatedDuration.inHours.toString();
    _minutesController.text = (route.estimatedDuration.inMinutes % 60).toString();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final double distance = double.parse(_distanceController.text);
      final int hours = int.tryParse(_hoursController.text) ?? 0;
      final int minutes = int.tryParse(_minutesController.text) ?? 0;
      final duration = Duration(hours: hours, minutes: minutes);

      final routeModel = _existingRoute != null
          ? _existingRoute!.copyWith(
              departureCityId: _departureCityId,
              arrivalCityId: _arrivalCityId,
              distanceKm: distance,
              estimatedDuration: duration,
            )
          : RouteModel(
              id: const Uuid().v4(),
              departureCityId: _departureCityId!,
              arrivalCityId: _arrivalCityId!,
              distanceKm: distance,
              estimatedDuration: duration,
            );

      if (_existingRoute != null) {
        _routeBloc.add(UpdateRoute(route: routeModel));
      } else {
        _routeBloc.add(CreateRoute(route: routeModel));
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNewRoute = widget.routeId == null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isNewRoute ? l10n.newRoute : l10n.editRoute),
      ),
      body: _isLoading
          ? const AppLoadingIndicator()
          : _errorMessage != null
              ? AppErrorWidget(
                  message: _errorMessage!,
                  onRetry: _loadData,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ville de départ
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: l10n.departureCity,
                            border: const OutlineInputBorder(),
                          ),
                          value: _departureCityId,
                          items: _cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city.id,
                              child: Text(city.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _departureCityId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.requiredField;
                            }
                            if (value == _arrivalCityId) {
                              return l10n.sameCityError;
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
                          value: _arrivalCityId,
                          items: _cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city.id,
                              child: Text(city.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _arrivalCityId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.requiredField;
                            }
                            if (value == _departureCityId) {
                              return l10n.sameCityError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Distance
                        TextFormField(
                          controller: _distanceController,
                          decoration: InputDecoration(
                            labelText: l10n.distanceKm,
                            border: const OutlineInputBorder(),
                            suffixText: 'km',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.requiredField;
                            }
                            if (double.tryParse(value) == null) {
                              return l10n.invalidNumber;
                            }
                            if (double.parse(value) <= 0) {
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
                                controller: _hoursController,
                                decoration: InputDecoration(
                                  labelText: l10n.hours,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  final hours = int.tryParse(value ?? '0') ?? 0;
                                  final minutes = int.tryParse(_minutesController.text) ?? 0;
                                  
                                  if (hours == 0 && minutes == 0) {
                                    return l10n.durationRequired;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _minutesController,
                                decoration: InputDecoration(
                                  labelText: l10n.minutes,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  FilteringTextInputFormatter.allow(RegExp(r'^([0-5]?[0-9])$')),
                                ],
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final minutes = int.tryParse(value);
                                    if (minutes == null || minutes >= 60) {
                                      return l10n.invalidMinutes;
                                    }
                                  }
                                  
                                  final hours = int.tryParse(_hoursController.text) ?? 0;
                                  final minutes = int.tryParse(value ?? '0') ?? 0;
                                  
                                  if (hours == 0 && minutes == 0) {
                                    return l10n.durationRequired;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(isNewRoute ? l10n.createRoute : l10n.saveChanges),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 