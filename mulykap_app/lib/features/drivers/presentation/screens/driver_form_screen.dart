import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mulykap_app/common/presentation/widgets/loading_indicator.dart';
import 'package:mulykap_app/features/buses/data/repositories/agency_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/drivers/domain/models/driver.dart';
import 'package:mulykap_app/features/drivers/domain/repositories/driver_repository.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class DriverFormScreen extends StatefulWidget {
  final Driver? driver;

  const DriverFormScreen({Key? key, this.driver}) : super(key: key);

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DriverRepository _driverRepository;
  late AgencyRepository _agencyRepository;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<AgencyModel> _agencies = [];
  
  // Contrôleurs pour les champs du formulaire
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  DateTime _licenseExpiryDate = DateTime.now().add(const Duration(days: 365));
  
  String? _selectedAgencyId;
  bool _isEditing = false;
  bool _isActive = true;
  
  @override
  void initState() {
    super.initState();
    _driverRepository = context.read<DriverRepository>();
    _agencyRepository = context.read<AgencyRepository>();
    _isEditing = widget.driver != null;
    _loadData();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Charger les agences
      final agencies = await _agencyRepository.getAllAgencies();
      
      setState(() {
        _agencies = agencies;
        _isLoading = false;
      });
      
      // Pré-remplir le formulaire si en mode édition
      if (_isEditing && widget.driver != null) {
        final driver = widget.driver!;
        _firstNameController.text = driver.firstName;
        _lastNameController.text = driver.lastName;
        _phoneNumberController.text = driver.phoneNumber;
        _licenseNumberController.text = driver.licenseNumber;
        _licenseExpiryDate = driver.licenseExpiryDate;
        _selectedAgencyId = driver.agencyId;
        _isActive = driver.isActive;
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _licenseExpiryDate) {
      setState(() {
        _licenseExpiryDate = picked;
      });
    }
  }
  
  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      if (_isEditing && widget.driver != null) {
        // Mettre à jour un chauffeur existant
        final updatedDriver = widget.driver!.copyWith(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneNumberController.text,
          licenseNumber: _licenseNumberController.text,
          licenseExpiryDate: _licenseExpiryDate,
          agencyId: _selectedAgencyId,
          isActive: _isActive,
        );
        
        await _driverRepository.updateDriver(updatedDriver);
      } else {
        // Créer un nouveau chauffeur
        await _driverRepository.createDriver(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneNumberController.text,
          licenseNumber: _licenseNumberController.text,
          licenseExpiryDate: _licenseExpiryDate,
          agencyId: _selectedAgencyId,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Retourner true pour indiquer le succès
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _isEditing 
        ? l10n.editDriver
        : l10n.addDriver;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(
          child: LoadingIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Remplacer AppBar par un header simple pour la boîte de dialogue
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveDriver,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.personalInformation,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            
                            // Prénom
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: l10n.firstName,
                                hintText: l10n.firstNameHint,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.firstNameRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Nom
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: l10n.lastName,
                                hintText: l10n.lastNameHint,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.lastNameRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Téléphone
                            TextFormField(
                              controller: _phoneNumberController,
                              decoration: InputDecoration(
                                labelText: l10n.phoneNumber,
                                hintText: l10n.phoneNumberHint,
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.phoneNumberRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Numéro de permis
                            TextFormField(
                              controller: _licenseNumberController,
                              decoration: InputDecoration(
                                labelText: l10n.licenseNumber,
                                hintText: l10n.licenseNumberHint,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.licenseNumberRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Date d'expiration du permis
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: l10n.licenseExpiryDate,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_licenseExpiryDate),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Agence
                            DropdownButtonFormField<String?>(
                              decoration: InputDecoration(
                                labelText: l10n.agency,
                                border: const OutlineInputBorder(),
                              ),
                              value: _selectedAgencyId,
                              hint: Text(l10n.selectAgency),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(l10n.noAgency),
                                ),
                                ..._agencies.map((agency) => DropdownMenuItem<String?>(
                                  value: agency.id,
                                  child: Text(agency.name),
                                )).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedAgencyId = value;
                                });
                              },
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 16),
                              // État actif/inactif
                              SwitchListTile(
                                title: Text(l10n.isActive),
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                              ),
                            ],
                          ],
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