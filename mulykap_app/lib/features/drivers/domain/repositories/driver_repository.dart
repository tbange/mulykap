import 'package:mulykap_app/features/drivers/domain/models/driver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DriverRepository {
  final _supabase = Supabase.instance.client;
  
  Future<List<Driver>> getAllDrivers() async {
    try {
      // Récupération des données de la table drivers avec toutes les colonnes
      final driversData = await _supabase
          .from('drivers')
          .select('*')
          .order('created_at', ascending: false);

      // Conversion des données vers notre modèle Driver
      final List<Driver> drivers = driversData.map<Driver>((item) {
        return Driver(
          id: item['id'] ?? '',
          firstName: item['first_name'] ?? 'Chauffeur',
          lastName: item['last_name'] ?? '',
          phoneNumber: item['phone_number'] ?? '',
          licenseNumber: item['license_number'] ?? '',
          licenseExpiryDate: item['license_expiry_date'] != null 
              ? DateTime.parse(item['license_expiry_date']) 
              : DateTime.now().add(const Duration(days: 365)),
          agencyId: item['agency_id'],
          agencyName: null, // Pas de jointure pour le moment
          isActive: item['is_active'] ?? true,
          createdAt: item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
          updatedAt: item['updated_at'] != null ? DateTime.parse(item['updated_at']) : DateTime.now(),
        );
      }).toList();
      
      return drivers;
    } catch (e) {
      print('Erreur lors du chargement des chauffeurs: $e');
      throw Exception('Erreur lors du chargement des chauffeurs: $e');
    }
  }
  
  Future<Driver> getDriverById(String id) async {
    try {
      final result = await _supabase
          .from('drivers')
          .select('*')
          .eq('id', id)
          .single();
      
      return Driver(
        id: result['id'] ?? '',
        firstName: result['first_name'] ?? 'Chauffeur',
        lastName: result['last_name'] ?? '',
        phoneNumber: result['phone_number'] ?? '',
        licenseNumber: result['license_number'] ?? '',
        licenseExpiryDate: result['license_expiry_date'] != null 
            ? DateTime.parse(result['license_expiry_date']) 
            : DateTime.now().add(const Duration(days: 365)),
        agencyId: result['agency_id'],
        agencyName: null, // Pas de jointure pour le moment
        isActive: result['is_active'] ?? true,
        createdAt: result['created_at'] != null ? DateTime.parse(result['created_at']) : DateTime.now(),
        updatedAt: result['updated_at'] != null ? DateTime.parse(result['updated_at']) : DateTime.now(),
      );
    } catch (e) {
      print('Erreur lors du chargement du chauffeur: $e');
      throw Exception('Erreur lors du chargement du chauffeur: $e');
    }
  }
  
  Future<Driver> createDriver({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String licenseNumber,
    required DateTime licenseExpiryDate,
    String? agencyId,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();
      
      // Inclure toutes les colonnes dans les données
      final driverData = {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'license_number': licenseNumber,
        'license_expiry_date': licenseExpiryDate.toIso8601String(),
        'agency_id': agencyId,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      await _supabase.from('drivers').insert(driverData);
      
      // Retourne un Driver avec les données fournies
      return Driver(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
        agencyId: agencyId,
        agencyName: null,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Erreur lors de la création du chauffeur: $e');
      throw Exception('Erreur lors de la création du chauffeur: $e');
    }
  }
  
  Future<Driver> updateDriver(Driver driver) async {
    try {
      final now = DateTime.now();
      // Mettre à jour toutes les colonnes
      final driverData = {
        'first_name': driver.firstName,
        'last_name': driver.lastName,
        'phone_number': driver.phoneNumber,
        'license_number': driver.licenseNumber,
        'license_expiry_date': driver.licenseExpiryDate.toIso8601String(),
        'agency_id': driver.agencyId,
        'is_active': driver.isActive,
        'updated_at': now.toIso8601String(),
      };
      
      await _supabase
          .from('drivers')
          .update(driverData)
          .eq('id', driver.id);
      
      // Retourne le driver mis à jour
      return driver.copyWith(updatedAt: now);
    } catch (e) {
      print('Erreur lors de la mise à jour du chauffeur: $e');
      throw Exception('Erreur lors de la mise à jour du chauffeur: $e');
    }
  }
  
  Future<void> deleteDriver(String id) async {
    try {
      await _supabase
          .from('drivers')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erreur lors de la suppression du chauffeur: $e');
      throw Exception('Erreur lors de la suppression du chauffeur: $e');
    }
  }
} 