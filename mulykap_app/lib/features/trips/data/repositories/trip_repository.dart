import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Repository pour gérer les voyages simples
class TripRepository {
  final SupabaseClient _supabaseClient;

  TripRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  /// Récupérer tous les voyages
  Future<List<TripModel>> getAllTrips() async {
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate),
            drivers!inner(
              id,
              user_profiles!inner(first_name, last_name)
            )
          ''')
          .order('departure_time', ascending: true);

      return response.map<TripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        // Construire le nom du chauffeur
        if (trip['drivers'] != null && trip['drivers']['user_profiles'] != null) {
          final profile = trip['drivers']['user_profiles'];
          final firstName = profile['first_name'] ?? '';
          final lastName = profile['last_name'] ?? '';
          tripData['driver_name'] = '$firstName $lastName'.trim();
        }
        
        return TripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages: $e');
    }
  }

  /// Récupérer les voyages par itinéraire
  Future<List<TripModel>> getTripsByRoute(String routeId) async {
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate),
            drivers!inner(
              id,
              user_profiles!inner(first_name, last_name)
            )
          ''')
          .eq('route_id', routeId)
          .order('departure_time', ascending: true);

      return response.map<TripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        // Construire le nom du chauffeur
        if (trip['drivers'] != null && trip['drivers']['user_profiles'] != null) {
          final profile = trip['drivers']['user_profiles'];
          final firstName = profile['first_name'] ?? '';
          final lastName = profile['last_name'] ?? '';
          tripData['driver_name'] = '$firstName $lastName'.trim();
        }
        
        return TripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages par itinéraire: $e');
    }
  }

  /// Récupérer les voyages par bus
  Future<List<TripModel>> getTripsByBus(String busId) async {
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate),
            drivers!inner(
              id,
              user_profiles!inner(first_name, last_name)
            )
          ''')
          .eq('bus_id', busId)
          .order('departure_time', ascending: true);

      return response.map<TripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        // Construire le nom du chauffeur
        if (trip['drivers'] != null && trip['drivers']['user_profiles'] != null) {
          final profile = trip['drivers']['user_profiles'];
          final firstName = profile['first_name'] ?? '';
          final lastName = profile['last_name'] ?? '';
          tripData['driver_name'] = '$firstName $lastName'.trim();
        }
        
        return TripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages par bus: $e');
    }
  }

  /// Récupérer les voyages par chauffeur
  Future<List<TripModel>> getTripsByDriver(String driverId) async {
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate),
            drivers!inner(
              id,
              user_profiles!inner(first_name, last_name)
            )
          ''')
          .eq('driver_id', driverId)
          .order('departure_time', ascending: true);

      return response.map<TripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        // Construire le nom du chauffeur
        if (trip['drivers'] != null && trip['drivers']['user_profiles'] != null) {
          final profile = trip['drivers']['user_profiles'];
          final firstName = profile['first_name'] ?? '';
          final lastName = profile['last_name'] ?? '';
          tripData['driver_name'] = '$firstName $lastName'.trim();
        }
        
        return TripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages par chauffeur: $e');
    }
  }

  /// Récupérer un voyage par son ID
  Future<TripModel> getTripById(String id) async {
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate),
            drivers!inner(
              id,
              user_profiles!inner(first_name, last_name)
            )
          ''')
          .eq('id', id)
          .single();

      final Map<String, dynamic> tripData = Map<String, dynamic>.from(response);
      
      // Extraire les données des relations
      tripData['route_name'] = response['routes']['name'];
      tripData['bus_plate'] = response['buses']['license_plate'];
      
      // Construire le nom du chauffeur
      if (response['drivers'] != null && response['drivers']['user_profiles'] != null) {
        final profile = response['drivers']['user_profiles'];
        final firstName = profile['first_name'] ?? '';
        final lastName = profile['last_name'] ?? '';
        tripData['driver_name'] = '$firstName $lastName'.trim();
      }

      return TripModel.fromMap(tripData);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du voyage: $e');
    }
  }

  /// Créer un nouveau voyage
  Future<TripModel> createTrip(TripModel trip) async {
    try {
      final String id = trip.id.isEmpty ? const Uuid().v4() : trip.id;
      final Map<String, dynamic> tripData = trip.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap();

      await _supabaseClient
          .from('trips')
          .insert(tripData);

      return getTripById(id);
    } catch (e) {
      throw Exception('Erreur lors de la création du voyage: $e');
    }
  }

  /// Mettre à jour un voyage existant
  Future<TripModel> updateTrip(TripModel trip) async {
    try {
      final Map<String, dynamic> tripData = trip.copyWith(
        updatedAt: DateTime.now(),
      ).toMap();

      await _supabaseClient
          .from('trips')
          .update(tripData)
          .eq('id', trip.id);

      return getTripById(trip.id);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du voyage: $e');
    }
  }

  /// Mettre à jour le statut d'un voyage
  Future<TripModel> updateTripStatus(String id, TripStatus status) async {
    try {
      await _supabaseClient
          .from('trips')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      return getTripById(id);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut du voyage: $e');
    }
  }

  /// Supprimer un voyage
  Future<void> deleteTrip(String id) async {
    try {
      await _supabaseClient
          .from('trips')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du voyage: $e');
    }
  }
} 