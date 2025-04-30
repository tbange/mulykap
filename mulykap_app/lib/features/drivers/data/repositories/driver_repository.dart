import 'package:mulykap_app/features/drivers/domain/models/driver_model.dart';
import 'package:mulykap_app/features/auth/domain/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DriverRepository {
  final SupabaseClient _supabaseClient;

  DriverRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Récupérer tous les chauffeurs avec leurs informations de profil
  Future<List<DriverModel>> getAllDrivers() async {
    try {
      // Récupérer les chauffeurs avec leurs données de base sans utiliser la jointure problématique
      final driversResponse = await _supabaseClient
          .from('drivers')
          .select('*')
          .order('created_at', ascending: false);

      List<DriverModel> drivers = [];

      for (var driverData in driversResponse) {
        final Map<String, dynamic> driverMap = Map<String, dynamic>.from(driverData);
        
        // Créer le modèle du chauffeur en utilisant directement les champs locaux
        drivers.add(DriverModel(
          id: driverMap['id'],
          licenseNumber: driverMap['license_number'] ?? '',
          userId: driverMap['user_id'],
          agencyId: driverMap['agency_id'],
          firstName: driverMap['first_name'],
          lastName: driverMap['last_name'],
          phone: driverMap['phone_number'],
          createdAt: driverMap['created_at'] != null ? DateTime.parse(driverMap['created_at']) : null,
          updatedAt: driverMap['updated_at'] != null ? DateTime.parse(driverMap['updated_at']) : null,
        ));
      }

      return drivers;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des chauffeurs: $e');
    }
  }

  // Récupérer un chauffeur par son ID
  Future<DriverModel> getDriverById(String id) async {
    try {
      final driverResponse = await _supabaseClient
          .from('drivers')
          .select('*')
          .eq('id', id)
          .single();

      // Créer le modèle en utilisant directement les champs du chauffeur
      return DriverModel(
        id: driverResponse['id'],
        licenseNumber: driverResponse['license_number'] ?? '',
        userId: driverResponse['user_id'],
        agencyId: driverResponse['agency_id'],
        firstName: driverResponse['first_name'],
        lastName: driverResponse['last_name'],
        phone: driverResponse['phone_number'],
        createdAt: driverResponse['created_at'] != null ? DateTime.parse(driverResponse['created_at']) : null,
        updatedAt: driverResponse['updated_at'] != null ? DateTime.parse(driverResponse['updated_at']) : null,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du chauffeur: $e');
    }
  }

  // Créer un nouveau chauffeur
  Future<DriverModel> createDriver({
    required String licenseNumber,
    String? userId,
    String? agencyId,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final id = const Uuid().v4();
      
      // Créer un compte utilisateur si les informations sont fournies et qu'il n'y a pas de userId
      if (userId == null && firstName != null && lastName != null) {
        // Générer un email unique basé sur le nom et le numéro de permis
        final email = '${firstName.toLowerCase()}.${lastName.toLowerCase()}.${licenseNumber.replaceAll(' ', '')}.driver@mulykap.com';
        final password = 'MulykDriver${const Uuid().v4().substring(0, 8)}'; // Mot de passe temporaire
        
        // Créer l'utilisateur dans Auth
        final authResponse = await _supabaseClient.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
            password: password,
            emailConfirm: true,
          ),
        );
        
        // Vérifier que l'utilisateur a été créé correctement
        if (authResponse.user != null) {
          userId = authResponse.user!.id;
          
          // Créer le profil utilisateur
          await _supabaseClient.from('user_profiles').insert({
            'user_id': userId,
            'first_name': firstName,
            'last_name': lastName,
            'phone': phone,
            'status': 'active',
          });
        } else {
          throw Exception('Échec de la création de l\'utilisateur');
        }
      }
      
      // Créer le chauffeur
      final driverData = {
        'id': id,
        'license_number': licenseNumber,
        'user_id': userId,
        'agency_id': agencyId,
      };
      
      await _supabaseClient.from('drivers').insert(driverData);
      
      // Récupérer le chauffeur créé avec toutes ses informations
      return getDriverById(id);
    } catch (e) {
      throw Exception('Erreur lors de la création du chauffeur: $e');
    }
  }

  // Mettre à jour un chauffeur
  Future<DriverModel> updateDriver(DriverModel driver) async {
    try {
      // Vérifier que l'ID du chauffeur est valide
      if (driver.id.isEmpty) {
        throw Exception('ID du chauffeur non valide');
      }
      
      await _supabaseClient
          .from('drivers')
          .update({
            'license_number': driver.licenseNumber,
            'agency_id': driver.agencyId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driver.id);
      
      // Mettre à jour le profil utilisateur si disponible
      if (driver.userId != null && (driver.firstName != null || driver.lastName != null || driver.phone != null)) {
        final updateData = <String, dynamic>{};
        
        if (driver.firstName != null) updateData['first_name'] = driver.firstName;
        if (driver.lastName != null) updateData['last_name'] = driver.lastName;
        if (driver.phone != null) updateData['phone'] = driver.phone;
        
        if (updateData.isNotEmpty) {
          final String userId = driver.userId!;
          await _supabaseClient
              .from('user_profiles')
              .update(updateData)
              .eq('user_id', userId);
        }
      }
      
      return getDriverById(driver.id);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du chauffeur: $e');
    }
  }

  // Supprimer un chauffeur
  Future<void> deleteDriver(String id) async {
    try {
      // Récupérer d'abord les informations du chauffeur
      final driver = await getDriverById(id);
      
      // Supprimer le chauffeur
      await _supabaseClient.from('drivers').delete().eq('id', id);
      
      // Si le chauffeur avait un utilisateur associé, ne pas le supprimer pour l'instant
      // car il pourrait être utilisé ailleurs. La suppression des utilisateurs 
      // devrait être gérée séparément.
    } catch (e) {
      throw Exception('Erreur lors de la suppression du chauffeur: $e');
    }
  }

  // Récupérer les chauffeurs par agence
  Future<List<DriverModel>> getDriversByAgency(String agencyId) async {
    try {
      if (agencyId.isEmpty) {
        throw Exception('ID d\'agence non valide');
      }
      
      final driversResponse = await _supabaseClient
          .from('drivers')
          .select('*')
          .eq('agency_id', agencyId)
          .order('created_at', ascending: false);

      List<DriverModel> drivers = [];

      for (var driverData in driversResponse) {
        final Map<String, dynamic> driverMap = Map<String, dynamic>.from(driverData);
        
        drivers.add(DriverModel(
          id: driverMap['id'],
          licenseNumber: driverMap['license_number'] ?? '',
          userId: driverMap['user_id'],
          agencyId: driverMap['agency_id'],
          firstName: driverMap['first_name'],
          lastName: driverMap['last_name'],
          phone: driverMap['phone_number'],
          createdAt: driverMap['created_at'] != null ? DateTime.parse(driverMap['created_at']) : null,
          updatedAt: driverMap['updated_at'] != null ? DateTime.parse(driverMap['updated_at']) : null,
        ));
      }

      return drivers;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des chauffeurs par agence: $e');
    }
  }
} 