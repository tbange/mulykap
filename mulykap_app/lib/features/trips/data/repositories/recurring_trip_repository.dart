import 'package:mulykap_app/features/trips/domain/models/recurring_trip_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Repository pour gérer les voyages récurrents
class RecurringTripRepository {
  final SupabaseClient _supabaseClient;

  RecurringTripRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  /// Récupérer tous les voyages récurrents
  Future<List<RecurringTripModel>> getAllRecurringTrips() async {
    try {
      final response = await _supabaseClient
          .from('recurring_trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate)
          ''')
          .order('departure_time', ascending: true);

      return response.map<RecurringTripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        return RecurringTripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages récurrents: $e');
    }
  }

  /// Récupérer les voyages récurrents par itinéraire
  Future<List<RecurringTripModel>> getRecurringTripsByRoute(String routeId) async {
    try {
      final response = await _supabaseClient
          .from('recurring_trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate)
          ''')
          .eq('route_id', routeId)
          .order('departure_time', ascending: true);

      return response.map<RecurringTripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        return RecurringTripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages récurrents par itinéraire: $e');
    }
  }

  /// Récupérer les voyages récurrents par bus
  Future<List<RecurringTripModel>> getRecurringTripsByBus(String busId) async {
    try {
      final response = await _supabaseClient
          .from('recurring_trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate)
          ''')
          .eq('bus_id', busId)
          .order('departure_time', ascending: true);

      return response.map<RecurringTripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        return RecurringTripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages récurrents par bus: $e');
    }
  }

  /// Récupérer les voyages récurrents actifs
  Future<List<RecurringTripModel>> getActiveRecurringTrips() async {
    try {
      final now = DateTime.now();
      final formattedDate = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      final response = await _supabaseClient
          .from('recurring_trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate)
          ''')
          .eq('is_active', true)
          .lte('valid_from', formattedDate)
          .gte('valid_until', formattedDate)
          .order('departure_time', ascending: true);

      return response.map<RecurringTripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les données des relations
        tripData['route_name'] = trip['routes']['name'];
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        return RecurringTripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages récurrents actifs: $e');
    }
  }

  /// Récupérer un voyage récurrent par son ID
  Future<RecurringTripModel> getRecurringTripById(String id) async {
    try {
      final response = await _supabaseClient
          .from('recurring_trips')
          .select('''
            *,
            routes!inner(name),
            buses!inner(license_plate)
          ''')
          .eq('id', id)
          .single();

      final Map<String, dynamic> tripData = Map<String, dynamic>.from(response);
      
      // Extraire les données des relations
      tripData['route_name'] = response['routes']['name'];
      tripData['bus_plate'] = response['buses']['license_plate'];

      return RecurringTripModel.fromMap(tripData);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du voyage récurrent: $e');
    }
  }

  /// Créer un nouveau voyage récurrent
  Future<RecurringTripModel> createRecurringTrip(RecurringTripModel trip) async {
    try {
      final String id = trip.id.isEmpty ? const Uuid().v4() : trip.id;
      final Map<String, dynamic> tripData = trip.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap();

      await _supabaseClient
          .from('recurring_trips')
          .insert(tripData);

      return getRecurringTripById(id);
    } catch (e) {
      throw Exception('Erreur lors de la création du voyage récurrent: $e');
    }
  }

  /// Mettre à jour un voyage récurrent existant
  Future<RecurringTripModel> updateRecurringTrip(RecurringTripModel trip) async {
    try {
      final Map<String, dynamic> tripData = trip.copyWith(
        updatedAt: DateTime.now(),
      ).toMap();

      await _supabaseClient
          .from('recurring_trips')
          .update(tripData)
          .eq('id', trip.id);

      return getRecurringTripById(trip.id);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du voyage récurrent: $e');
    }
  }

  /// Activer ou désactiver un voyage récurrent
  Future<RecurringTripModel> toggleRecurringTripActive(String id, bool isActive) async {
    try {
      await _supabaseClient
          .from('recurring_trips')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      return getRecurringTripById(id);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut du voyage récurrent: $e');
    }
  }

  /// Supprimer un voyage récurrent
  Future<void> deleteRecurringTrip(String id) async {
    try {
      await _supabaseClient
          .from('recurring_trips')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du voyage récurrent: $e');
    }
  }
} 