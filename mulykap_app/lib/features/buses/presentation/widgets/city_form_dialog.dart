import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:uuid/uuid.dart';

class CityFormDialog extends StatefulWidget {
  final CityModel? city;
  final bool isEditing;

  const CityFormDialog({
    Key? key,
    this.city,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<CityFormDialog> createState() => _CityFormDialogState();

  /// Affiche la boîte de dialogue pour créer ou modifier une ville
  static Future<void> show({
    required BuildContext context,
    CityModel? city,
    bool isEditing = false,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: CityFormDialog(
              city: city,
              isEditing: isEditing,
            ),
          ),
        );
      },
    );
  }
}

class _CityFormDialogState extends State<CityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _code;
  late String _province;
  late bool _isMain;
  String? _postalCode;
  String? _country;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _name = widget.city?.name ?? '';
    _code = widget.city?.code ?? 'CT-';
    _province = widget.city?.province ?? '';
    _isMain = widget.city?.isMain ?? false;
    _postalCode = widget.city?.postalCode;
    _country = widget.city?.country ?? 'RDC';
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();

      setState(() {
        _isSubmitting = true;
      });

      if (widget.isEditing) {
        final updatedCity = widget.city!.copyWith(
          name: _name,
          code: _code,
          province: _province,
          isMain: _isMain,
          postalCode: _postalCode,
          country: _country,
        );
        context.read<CityBloc>().add(CityUpdate(updatedCity));
      } else {
        final newCity = CityModel(
          id: '', // L'ID sera généré par le backend
          code: _code,
          name: _name,
          province: _province,
          isMain: _isMain,
          postalCode: _postalCode,
          country: _country,
        );
        context.read<CityBloc>().add(CityCreate(newCity));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                widget.isEditing ? 'Modifier une Ville' : 'Ajouter une Ville',
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
                    // Code de la ville
                    TextFormField(
                      initialValue: _code,
                      decoration: const InputDecoration(
                        labelText: 'Code (format CT-XXX requis)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: CT-LBU',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le code est requis';
                        }
                        if (!RegExp(r'^CT-[A-Z0-9]{3}$').hasMatch(value)) {
                          return 'Format CT-XXX requis (XXX = 3 caractères)';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _code = value!.toUpperCase();
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom de la ville
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la ville',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Lubumbashi',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Province
                    TextFormField(
                      initialValue: _province,
                      decoration: const InputDecoration(
                        labelText: 'Province',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Haut-Katanga',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La province est requise';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _province = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Code postal
                    TextFormField(
                      initialValue: _postalCode,
                      decoration: const InputDecoration(
                        labelText: 'Code postal (optionnel)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 1700',
                      ),
                      onSaved: (value) {
                        _postalCode = value?.isEmpty ?? true ? null : value;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Pays
                    TextFormField(
                      initialValue: _country,
                      decoration: const InputDecoration(
                        labelText: 'Pays',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: RDC',
                      ),
                      onSaved: (value) {
                        _country = value?.isEmpty ?? true ? null : value;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Ville principale
                    SwitchListTile(
                      title: const Text('Ville principale'),
                      subtitle: const Text('Affichée en priorité dans les listes'),
                      value: _isMain,
                      activeColor: primaryColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onChanged: (value) {
                        setState(() {
                          _isMain = value;
                        });
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
                  backgroundColor: primaryColor,
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