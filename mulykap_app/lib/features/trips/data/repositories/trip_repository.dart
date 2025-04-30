import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Repository pour gérer les voyages simples
class TripRepository {
  final SupabaseClient _supabaseClient;
  
  // Cache pour les voyages
  final Map<String, List<TripModel>> _tripsCache = {};
  final Map<String, DateTime> _tripsCacheTimestamp = {};
  
  // Cache pour les recherches par route, bus et conducteur
  final Map<String, List<TripModel>> _filteredTripsCache = {};
  final Map<String, DateTime> _filteredTripsCacheTimestamp = {};
  
  // Durée de validité du cache en minutes
  final int _cacheDuration = 5;

  TripRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;
      
  /// Vérifier si le cache est valide
  bool _isCacheValid(String cacheKey) {
    if (!_tripsCache.containsKey(cacheKey) || !_tripsCacheTimestamp.containsKey(cacheKey)) {
      return false;
    }
    
    final timestamp = _tripsCacheTimestamp[cacheKey]!;
    final now = DateTime.now();
    final difference = now.difference(timestamp).inMinutes;
    
    return difference < _cacheDuration;
  }
  
  /// Récupérer tous les voyages
  Future<List<TripModel>> getAllTrips() async {
    final cacheKey = 'all_trips';
    
    // Utiliser le cache si disponible et valide
    if (_isCacheValid(cacheKey)) {
      print('Utilisation du cache pour tous les voyages');
      return _tripsCache[cacheKey]!;
    }
    
    try {
      // 1. Récupérer tous les voyages avec les relations principales en une seule requête
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes:route_id(*,
              departure_city:cities!routes_departure_city_id_fkey(*),
              arrival_city:cities!routes_arrival_city_id_fkey(*)
            ),
            buses:bus_id(license_plate),
            drivers:driver_id(first_name, last_name)
          ''')
          .order('departure_time', ascending: true);

      // 2. Convertir en modèles en utilisant les données déjà récupérées
      final trips = response.map<TripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les noms des villes de l'itinéraire
        if (trip['routes'] != null) {
          final routeData = trip['routes'];
          if (routeData['departure_city'] != null && routeData['arrival_city'] != null) {
            final departureCityName = routeData['departure_city']['name'] as String? ?? 'Inconnu';
            final arrivalCityName = routeData['arrival_city']['name'] as String? ?? 'Inconnu';
            tripData['route_name'] = '$departureCityName - $arrivalCityName';
          } else {
            tripData['route_name'] = 'Itinéraire inconnu';
          }
        }
        
        // Extraire les données du bus
        if (trip['buses'] != null) {
          tripData['bus_plate'] = trip['buses']['license_plate'];
        }
        
        // Extraire les données du chauffeur
        if (trip['drivers'] != null) {
          final driverData = trip['drivers'];
          final firstName = driverData['first_name'] ?? '';
          final lastName = driverData['last_name'] ?? '';
          tripData['driver_name'] = '$firstName $lastName'.trim();
        }
        
        return TripModel.fromMap(tripData);
      }).toList();
      
      // Mettre à jour le cache
      _tripsCache[cacheKey] = trips;
      _tripsCacheTimestamp[cacheKey] = DateTime.now();
      
      return trips;
    } catch (e) {
      print('Erreur détaillée lors de la récupération des voyages: $e');
      throw Exception('Erreur lors de la récupération des voyages: $e');
    }
  }

  /// Actualiser le cache
  void clearCache() {
    _tripsCache.clear();
    _tripsCacheTimestamp.clear();
    _filteredTripsCache.clear();
    _filteredTripsCacheTimestamp.clear();
    print('Cache des voyages effacé');
  }

  /// Vérifie si un cache filtré est valide
  bool _isFilteredCacheValid(String cacheKey) {
    if (!_filteredTripsCache.containsKey(cacheKey) || 
        !_filteredTripsCacheTimestamp.containsKey(cacheKey)) {
      return false;
    }
    final timestamp = _filteredTripsCacheTimestamp[cacheKey];
    final now = DateTime.now();
    return now.difference(timestamp!).inMinutes < _cacheDuration;
  }

  /// Récupérer tous les voyages pour un itinéraire donné
  Future<List<TripModel>> getTripsByRoute(String routeId) async {
    final String cacheKey = 'route_$routeId';
    
    // Utiliser le cache si valide
    if (_isFilteredCacheValid(cacheKey)) {
      print('Utilisation du cache pour les voyages de l\'itinéraire $routeId');
      return _filteredTripsCache[cacheKey]!;
    }
    
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes:route_id (*,
              departure_city:departure_city_id (id, name),
              arrival_city:arrival_city_id (id, name)
            ),
            buses:bus_id (id, license_plate, model, capacity),
            drivers:driver_id (id, first_name, last_name, phone, email)
          ''')
          .eq('route_id', routeId)
          .order('departure_time');

      final List<TripModel> trips = List<Map<String, dynamic>>.from(response)
          .map((data) {
            return TripModel.fromMap(data);
          })
          .toList();
          
      // Mettre à jour le cache
      _filteredTripsCache[cacheKey] = trips;
      _filteredTripsCacheTimestamp[cacheKey] = DateTime.now();
      
      return trips;
    } catch (e) {
      print('Erreur lors de la récupération des voyages par itinéraire: $e');
      throw Exception('Erreur lors de la récupération des voyages par itinéraire: $e');
    }
  }

  /// Récupérer tous les voyages pour un bus donné
  Future<List<TripModel>> getTripsByBus(String busId) async {
    final String cacheKey = 'bus_$busId';
    
    // Utiliser le cache si valide
    if (_isFilteredCacheValid(cacheKey)) {
      print('Utilisation du cache pour les voyages du bus $busId');
      return _filteredTripsCache[cacheKey]!;
    }
    
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes:route_id (*,
              departure_city:departure_city_id (id, name),
              arrival_city:arrival_city_id (id, name)
            ),
            buses:bus_id (id, license_plate, model, capacity),
            drivers:driver_id (id, first_name, last_name, phone, email)
          ''')
          .eq('bus_id', busId)
          .order('departure_time');

      final List<TripModel> trips = List<Map<String, dynamic>>.from(response)
          .map((data) {
            return TripModel.fromMap(data);
          })
          .toList();
          
      // Mettre à jour le cache
      _filteredTripsCache[cacheKey] = trips;
      _filteredTripsCacheTimestamp[cacheKey] = DateTime.now();
      
      return trips;
    } catch (e) {
      print('Erreur lors de la récupération des voyages par bus: $e');
      throw Exception('Erreur lors de la récupération des voyages par bus: $e');
    }
  }

  /// Récupérer tous les voyages pour un conducteur donné
  Future<List<TripModel>> getTripsByDriver(String driverId) async {
    final String cacheKey = 'driver_$driverId';
    
    // Utiliser le cache si valide
    if (_isFilteredCacheValid(cacheKey)) {
      print('Utilisation du cache pour les voyages du conducteur $driverId');
      return _filteredTripsCache[cacheKey]!;
    }
    
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes:route_id (*,
              departure_city:departure_city_id (id, name),
              arrival_city:arrival_city_id (id, name)
            ),
            buses:bus_id (id, license_plate, model, capacity),
            drivers:driver_id (id, first_name, last_name, phone, email)
          ''')
          .eq('driver_id', driverId)
          .order('departure_time');

      final List<TripModel> trips = List<Map<String, dynamic>>.from(response)
          .map((data) {
            return TripModel.fromMap(data);
          })
          .toList();
          
      // Mettre à jour le cache
      _filteredTripsCache[cacheKey] = trips;
      _filteredTripsCacheTimestamp[cacheKey] = DateTime.now();
      
      return trips;
    } catch (e) {
      print('Erreur lors de la récupération des voyages par conducteur: $e');
      throw Exception('Erreur lors de la récupération des voyages par conducteur: $e');
    }
  }

  /// Récupérer les voyages dans une plage de dates spécifique
  Future<List<TripModel>> getTripsByDateRange(DateTime startDate, DateTime endDate) async {
    final String cacheKey = 'date_range_${startDate.toIso8601String()}_${endDate.toIso8601String()}';
    
    // Utiliser le cache si valide
    if (_isFilteredCacheValid(cacheKey)) {
      print('Utilisation du cache pour les voyages entre ${startDate.toString()} et ${endDate.toString()}');
      return _filteredTripsCache[cacheKey]!;
    }
    
    try {
      // Convertir les dates en format ISO sans les heures (YYYY-MM-DD)
      final String startDateStr = startDate.toIso8601String().split('T')[0];
      final String endDateStr = endDate.toIso8601String().split('T')[0] + 'T23:59:59';
      
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes:route_id (*,
              departure_city:cities!routes_departure_city_id_fkey(*),
              arrival_city:cities!routes_arrival_city_id_fkey(*)
            ),
            buses:bus_id (license_plate),
            drivers:driver_id (first_name, last_name)
          ''')
          .gte('departure_time', startDateStr)
          .lte('departure_time', endDateStr)
          .order('departure_time', ascending: true);

      final List<TripModel> trips = response.map<TripModel>((trip) {
        final Map<String, dynamic> tripData = Map<String, dynamic>.from(trip);
        
        // Extraire les noms des villes de l'itinéraire
        if (trip['routes'] != null) {
          final routeData = trip['routes'];
          if (routeData['departure_city'] != null && routeData['arrival_city'] != null) {
            final departureCityName = routeData['departure_city']['name'] as String? ?? 'Inconnu';
            final arrivalCityName = routeData['arrival_city']['name'] as String? ?? 'Inconnu';
            tripData['route_name'] = '$departureCityName - $arrivalCityName';
          } else {
            tripData['route_name'] = 'Itinéraire inconnu';
          }
        }
        
        // Extraire les données du bus
        if (trip['buses'] != null) {
          tripData['bus_plate'] = trip['buses']['license_plate'];
        }
        
        // Extraire les données du chauffeur
        if (trip['drivers'] != null) {
          final driverData = trip['drivers'];
          final firstName = driverData['first_name'] ?? '';
          final lastName = driverData['last_name'] ?? '';
          tripData['driver_name'] = '$firstName $lastName'.trim();
        }
        
        return TripModel.fromMap(tripData);
      }).toList();
          
      // Mettre à jour le cache
      _filteredTripsCache[cacheKey] = trips;
      _filteredTripsCacheTimestamp[cacheKey] = DateTime.now();
      
      return trips;
    } catch (e) {
      print('Erreur lors de la récupération des voyages par plage de dates: $e');
      throw Exception('Erreur lors de la récupération des voyages par plage de dates: $e');
    }
  }

  /// Récupérer un voyage par son ID
  Future<TripModel> getTripById(String id) async {
    try {
      final response = await _supabaseClient
          .from('trips')
          .select('''
            *,
            routes:route_id(*,
              departure_city:cities!routes_departure_city_id_fkey(*),
              arrival_city:cities!routes_arrival_city_id_fkey(*)
            ),
            buses:bus_id(license_plate),
            drivers:driver_id(first_name, last_name)
          ''')
          .eq('id', id)
          .single();

      final Map<String, dynamic> tripData = Map<String, dynamic>.from(response);
      
      // Extraire les noms des villes de l'itinéraire
      if (response['routes'] != null) {
        final routeData = response['routes'];
        if (routeData['departure_city'] != null && routeData['arrival_city'] != null) {
          final departureCityName = routeData['departure_city']['name'] as String? ?? 'Inconnu';
          final arrivalCityName = routeData['arrival_city']['name'] as String? ?? 'Inconnu';
          tripData['route_name'] = '$departureCityName - $arrivalCityName';
        } else {
          tripData['route_name'] = 'Itinéraire inconnu';
        }
      }
      
      // Extraire les données du bus
      if (response['buses'] != null) {
        tripData['bus_plate'] = response['buses']['license_plate'];
      }
      
      // Extraire les données du chauffeur
      if (response['drivers'] != null) {
        final driverData = response['drivers'];
        final firstName = driverData['first_name'] ?? '';
        final lastName = driverData['last_name'] ?? '';
        tripData['driver_name'] = '$firstName $lastName'.trim();
      }

      return TripModel.fromMap(tripData);
    } catch (e) {
      print('Erreur détaillée lors de la récupération du voyage: $e');
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
          
      // Effacer le cache après modification
      clearCache();

      return getTripById(id);
    } catch (e) {
      print('Erreur détaillée lors de la création du voyage: $e');
      throw Exception('Erreur lors de la création du voyage: $e');
    }
  }

  /// Mettre à jour un voyage existant
  Future<TripModel> updateTrip(TripModel trip) async {
    try {
      // Créer le map de données pour la mise à jour
      final Map<String, dynamic> tripData = {
        'route_id': trip.routeId,
        'bus_id': trip.busId,
        'driver_id': trip.driverId,
        'departure_time': trip.departureTime.toIso8601String(),
        'arrival_time': trip.arrivalTime.toIso8601String(),
        'base_price': trip.basePrice,
        'status': trip.status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Mise à jour du voyage: $tripData'); // Log pour déboguer
      
      await _supabaseClient
          .from('trips')
          .update(tripData)
          .eq('id', trip.id);
          
      // Effacer le cache après modification
      clearCache();

      return getTripById(trip.id);
    } catch (e) {
      print('Erreur détaillée lors de la mise à jour du voyage: $e'); // Log détaillé de l'erreur
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
          
      // Effacer le cache après modification
      clearCache();

      return getTripById(id);
    } catch (e) {
      print('Erreur détaillée lors de la mise à jour du statut: $e');
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
          
      // Effacer le cache après modification
      clearCache();
    } catch (e) {
      print('Erreur détaillée lors de la suppression: $e');
      throw Exception('Erreur lors de la suppression du voyage: $e');
    }
  }
} 