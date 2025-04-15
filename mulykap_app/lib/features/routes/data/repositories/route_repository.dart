import 'package:flutter/foundation.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class RouteRepository {
  final SupabaseClient _supabaseClient;

  RouteRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Récupérer tous les itinéraires
  Future<List<RouteModel>> getAllRoutes() async {
    try {
      debugPrint('Début de récupération des itinéraires...');
      
      final response = await _supabaseClient
          .from('routes')
          .select()
          .order('created_at', ascending: false);

      final routesList = response.map<RouteModel>((route) => RouteModel.fromMap(route)).toList();
      
      debugPrint('Itinéraires récupérés avec succès: ${routesList.length}');
      
      return routesList;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des itinéraires: $e');
      throw Exception('Erreur lors de la récupération des itinéraires: $e');
    }
  }

  // Récupérer un itinéraire spécifique
  Future<RouteModel> getRouteById(String id) async {
    try {
      final response = await _supabaseClient
          .from('routes')
          .select()
          .eq('id', id)
          .single();

      return RouteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'itinéraire: $e');
    }
  }

  // Rechercher des itinéraires par ville de départ ou d'arrivée
  Future<List<RouteModel>> searchRoutes({
    String? departureCityId,
    String? arrivalCityId,
  }) async {
    try {
      var query = _supabaseClient
          .from('routes')
          .select();

      if (departureCityId != null) {
        query = query.eq('departure_city_id', departureCityId);
      }

      if (arrivalCityId != null) {
        query = query.eq('arrival_city_id', arrivalCityId);
      }

      final response = await query.order('created_at', ascending: false);
      return response.map<RouteModel>((route) => RouteModel.fromMap(route)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche des itinéraires: $e');
    }
  }

  // Créer un nouvel itinéraire
  Future<RouteModel> createRoute(RouteModel route) async {
    try {
      // Générer un nouvel ID si non fourni
      final routeMap = route.toMap();
      if (routeMap['id'] == null || routeMap['id'].isEmpty) {
        routeMap['id'] = const Uuid().v4();
      }

      final response = await _supabaseClient
          .from('routes')
          .insert(routeMap)
          .select()
          .single();

      return RouteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'itinéraire: $e');
    }
  }

  // Mettre à jour un itinéraire existant
  Future<RouteModel> updateRoute(RouteModel route) async {
    try {
      final response = await _supabaseClient
          .from('routes')
          .update(route.toMap())
          .eq('id', route.id)
          .select()
          .single();

      return RouteModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'itinéraire: $e');
    }
  }

  // Supprimer un itinéraire
  Future<void> deleteRoute(String id) async {
    try {
      await _supabaseClient
          .from('routes')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'itinéraire: $e');
    }
  }
} 