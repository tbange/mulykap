import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
            routes!inner(
              id,
              departure_city:cities!departure_city_id(name),
              arrival_city:cities!arrival_city_id(name)
            ),
            buses!inner(license_plate)
          ''')
          .order('created_at', ascending: false);

      return response.map<RecurringTripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Construire le nom de l'itinéraire à partir des villes
        final route = trip['routes'];
        final departureCityName = route['departure_city']['name'];
        final arrivalCityName = route['arrival_city']['name'];
        tripData['route_name'] = '$departureCityName - $arrivalCityName';
        
        // Extraire la plaque d'immatriculation du bus
        tripData['bus_plate'] = trip['buses']['license_plate'];
        
        return RecurringTripModel.fromMap(tripData);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des voyages récurrents: $e');
    }
  }

  /// Récupérer un voyage récurrent par son ID
  Future<RecurringTripModel> getRecurringTripById(String id) async {
    try {
      final response = await _supabaseClient
          .from('recurring_trips')
          .select('''
            *,
            routes!inner(
              id,
              departure_city:cities!departure_city_id(name),
              arrival_city:cities!arrival_city_id(name)
            ),
            buses!inner(license_plate)
          ''')
          .eq('id', id)
          .single();

      final Map<String, dynamic> tripData = Map<String, dynamic>.from(response);
      
      // Construire le nom de l'itinéraire à partir des villes
      final route = response['routes'];
      final departureCityName = route['departure_city']['name'];
      final arrivalCityName = route['arrival_city']['name'];
      tripData['route_name'] = '$departureCityName - $arrivalCityName';
      
      // Extraire la plaque d'immatriculation du bus
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

      // Noms complets des jours en français pour le débogage
      final List<String> weekdayNames = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
      final List<String> weekdaysFr = trip.weekdays.map((day) => weekdayNames[day - 1]).toList();

      print('Tentative d\'insertion du voyage récurrent avec les données:');
      print('ID: $id');
      print('Route ID: ${tripData['route_id']}');
      print('Bus ID: ${tripData['bus_id']}');
      print('Jours (indices): ${trip.weekdays}');
      print('Jours (français): $weekdaysFr');
      print('Jours (pour DB): ${tripData['weekdays']}');
      print('Départ: ${tripData['departure_time']}');
      print('Arrivée: ${tripData['arrival_time']}');
      print('Prix: ${tripData['base_price']}');
      print('Actif: ${tripData['is_active']}');
      print('Valide du: ${tripData['valid_from']}');
      print('Valide jusqu\'au: ${tripData['valid_until']}');

      final response = await _supabaseClient
          .from('recurring_trips')
          .insert(tripData)
          .select()
          .single();

      print('Voyage récurrent inséré avec succès: $response');
      return RecurringTripModel.fromMap(response);
    } catch (e) {
      print('ERREUR lors de la création du voyage récurrent: $e');
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

  /// Activer/désactiver un voyage récurrent
  Future<RecurringTripModel> toggleRecurringTripStatus(String id, bool isActive) async {
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
      throw Exception('Erreur lors de la modification du statut du voyage récurrent: $e');
    }
  }
} 