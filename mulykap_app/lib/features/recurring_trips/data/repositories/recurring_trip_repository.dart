import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';
import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';
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
            buses(license_plate)
          ''')
          .order('created_at', ascending: false);

      return response.map<RecurringTripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Construire le nom de l'itinéraire à partir des villes
        final route = trip['routes'];
        final departureCityName = route['departure_city']['name'];
        final arrivalCityName = route['arrival_city']['name'];
        tripData['route_name'] = '$departureCityName - $arrivalCityName';
        
        // Extraire la plaque d'immatriculation du bus s'il existe
        final buses = trip['buses'];
        if (buses != null && buses is List && buses.isNotEmpty) {
          tripData['bus_plate'] = buses[0]['license_plate'];
        } else {
          tripData['bus_plate'] = null;
        }
        
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
            buses(license_plate)
          ''')
          .eq('id', id)
          .single();

      final Map<String, dynamic> tripData = Map<String, dynamic>.from(response);
      
      // Construire le nom de l'itinéraire à partir des villes
      final route = response['routes'];
      final departureCityName = route['departure_city']['name'];
      final arrivalCityName = route['arrival_city']['name'];
      tripData['route_name'] = '$departureCityName - $arrivalCityName';
      
      // Extraire la plaque d'immatriculation du bus s'il existe
      final buses = response['buses'];
      if (buses != null && buses is List && buses.isNotEmpty) {
        tripData['bus_plate'] = buses[0]['license_plate'];
      } else {
        tripData['bus_plate'] = null;
      }

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

  /// Désactiver un voyage récurrent
  Future<RecurringTripModel> deactivateRecurringTrip(String id) async {
    try {
      await _supabaseClient
          .from('recurring_trips')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      return getRecurringTripById(id);
    } catch (e) {
      throw Exception('Erreur lors de la désactivation du voyage récurrent: $e');
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

  /// Générer des voyages réels à partir d'un modèle récurrent
  Future<int> generateTripsFromRecurringTrip({
    required String recurringTripId,
    required DateTime startDate,
    required DateTime endDate,
    String? driverId,
  }) async {
    try {
      // 1. Récupérer le modèle récurrent
      final recurringTrip = await getRecurringTripById(recurringTripId);
      
      if (!recurringTrip.isActive) {
        throw Exception('Le voyage récurrent n\'est pas actif');
      }
      
      // Vérifier les dates de validité
      final now = DateTime.now();
      if (recurringTrip.validFrom.isAfter(endDate) || 
          (recurringTrip.validUntil != null && recurringTrip.validUntil!.isBefore(startDate))) {
        throw Exception('La période spécifiée est en dehors de la période de validité du voyage récurrent');
      }
      
      // 2. Calculer les dates pour lesquelles nous devons générer des voyages
      final List<DateTime> tripDates = [];
      DateTime currentDate = _getEffectiveStartDate(startDate, recurringTrip.validFrom);
      final DateTime effectiveEndDate = _getEffectiveEndDate(endDate, recurringTrip.validUntil);
      
      while (currentDate.isBefore(effectiveEndDate) || currentDate.isAtSameMomentAs(effectiveEndDate)) {
        // Vérifier si le jour de la semaine est inclus dans le modèle récurrent
        final weekday = currentDate.weekday; // 1 = Lundi, 7 = Dimanche
        if (recurringTrip.weekdays.contains(weekday)) {
          tripDates.add(currentDate);
        }
        
        // Passer au jour suivant
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      // 3. Créer les voyages pour chaque date
      int createdCount = 0;
      
      for (final date in tripDates) {
        // Extraire les heures et minutes depuis le format time HH:MM:SS
        final departureTimeParts = recurringTrip.departureTime.split(':');
        final departureHour = int.parse(departureTimeParts[0]);
        final departureMinute = int.parse(departureTimeParts[1]);
        
        final arrivalTimeParts = recurringTrip.arrivalTime.split(':');
        final arrivalHour = int.parse(arrivalTimeParts[0]);
        final arrivalMinute = int.parse(arrivalTimeParts[1]);
        
        // Créer les DateTime pour le départ et l'arrivée
        final departureDateTime = DateTime(
          date.year, date.month, date.day, departureHour, departureMinute
        );
        
        final arrivalDateTime = DateTime(
          date.year, date.month, date.day, arrivalHour, arrivalMinute
        );
        
        // Si l'heure d'arrivée est plus petite que l'heure de départ, 
        // cela signifie que l'arrivée est le jour suivant
        final DateTime effectiveArrivalDateTime = departureDateTime.isAfter(arrivalDateTime) 
            ? arrivalDateTime.add(const Duration(days: 1)) 
            : arrivalDateTime;
        
        // Vérifier si un voyage existe déjà pour cette route, cette date et cette heure de départ
        final existingTrips = await _supabaseClient
            .from('trips')
            .select()
            .eq('route_id', recurringTrip.routeId)
            .gte('departure_time', departureDateTime.toIso8601String())
            .lte('departure_time', departureDateTime.add(const Duration(minutes: 5)).toIso8601String());
        
        if (existingTrips.isNotEmpty) {
          print('Un voyage existe déjà pour cette date et cette heure: ${departureDateTime.toIso8601String()}');
          continue; // Passer à la date suivante
        }
        
        // Créer le voyage
        final String id = const Uuid().v4();
        final tripData = {
          'id': id,
          'route_id': recurringTrip.routeId,
          'bus_id': recurringTrip.busId,
          'driver_id': driverId,
          'departure_time': departureDateTime.toIso8601String(),
          'arrival_time': effectiveArrivalDateTime.toIso8601String(),
          'base_price': recurringTrip.basePrice,
          'status': 'planned',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };
        
        await _supabaseClient
            .from('trips')
            .insert(tripData);
        
        createdCount++;
      }
      
      return createdCount;
    } catch (e) {
      print('Erreur lors de la génération des voyages: $e');
      throw Exception('Erreur lors de la génération des voyages: $e');
    }
  }
  
  /// Générer des voyages pour tous les modèles récurrents actifs
  Future<int> generateTripsForAllActiveRecurringTrips({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 1. Récupérer tous les voyages récurrents actifs
      final List<RecurringTripModel> activeTrips = await getAllRecurringTrips();
      final activeValidTrips = activeTrips.where((trip) => 
        trip.isActive && 
        (trip.validUntil == null || trip.validUntil!.isAfter(startDate)) &&
        trip.validFrom.isBefore(endDate)
      ).toList();
      
      // 2. Générer les voyages pour chaque modèle récurrent
      int totalCreated = 0;
      
      for (final trip in activeValidTrips) {
        try {
          final created = await generateTripsFromRecurringTrip(
            recurringTripId: trip.id,
            startDate: startDate,
            endDate: endDate,
            driverId: null, // Pas de chauffeur par défaut
          );
          
          totalCreated += created;
        } catch (e) {
          print('Erreur lors de la génération des voyages pour ${trip.id}: $e');
          // Continuer avec le prochain voyage récurrent
        }
      }
      
      return totalCreated;
    } catch (e) {
      throw Exception('Erreur lors de la génération des voyages pour tous les modèles récurrents: $e');
    }
  }
  
  // Méthodes utilitaires privées
  
  DateTime _getEffectiveStartDate(DateTime requestedStart, DateTime validFrom) {
    // Utiliser la date la plus récente entre requestedStart et validFrom
    return requestedStart.isAfter(validFrom) ? requestedStart : validFrom;
  }
  
  DateTime _getEffectiveEndDate(DateTime requestedEnd, DateTime? validUntil) {
    // Si validUntil est null ou après requestedEnd, utiliser requestedEnd
    if (validUntil == null || validUntil.isAfter(requestedEnd)) {
      return requestedEnd;
    }
    return validUntil;
  }
} 