import 'package:mulykap_app/features/routes/domain/models/route_stop_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class RouteStopRepository {
  final SupabaseClient _supabaseClient;

  RouteStopRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Récupérer tous les arrêts d'un itinéraire
  Future<List<RouteStopModel>> getStopsForRoute(String routeId) async {
    try {
      final response = await _supabaseClient
          .from('route_stops')
          .select()
          .eq('route_id', routeId)
          .order('stop_order', ascending: true);

      return response.map<RouteStopModel>((stop) => RouteStopModel.fromMap(stop)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des arrêts: $e');
    }
  }

  // Récupérer un arrêt spécifique
  Future<RouteStopModel> getStopById(String id) async {
    try {
      final response = await _supabaseClient
          .from('route_stops')
          .select()
          .eq('id', id)
          .single();

      return RouteStopModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'arrêt: $e');
    }
  }

  // Créer un nouvel arrêt
  Future<RouteStopModel> createStop(RouteStopModel stop) async {
    try {
      // Générer un nouvel ID si non fourni
      final stopMap = stop.toMap();
      if (stopMap['id'] == null || stopMap['id'].isEmpty) {
        stopMap['id'] = const Uuid().v4();
      }

      final response = await _supabaseClient
          .from('route_stops')
          .insert(stopMap)
          .select()
          .single();

      return RouteStopModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'arrêt: $e');
    }
  }

  // Mettre à jour un arrêt existant
  Future<RouteStopModel> updateStop(RouteStopModel stop) async {
    try {
      final response = await _supabaseClient
          .from('route_stops')
          .update(stop.toMap())
          .eq('id', stop.id)
          .select()
          .single();

      return RouteStopModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'arrêt: $e');
    }
  }

  // Supprimer un arrêt
  Future<void> deleteStop(String id) async {
    try {
      await _supabaseClient
          .from('route_stops')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'arrêt: $e');
    }
  }

  // Créer plusieurs arrêts en une seule opération
  Future<List<RouteStopModel>> createMultipleStops(List<RouteStopModel> stops) async {
    if (stops.isEmpty) return [];

    try {
      final stopsMap = stops.map((stop) {
        final map = stop.toMap();
        if (map['id'] == null || map['id'].isEmpty) {
          map['id'] = const Uuid().v4();
        }
        return map;
      }).toList();

      final response = await _supabaseClient
          .from('route_stops')
          .insert(stopsMap)
          .select();

      return response.map<RouteStopModel>((stop) => RouteStopModel.fromMap(stop)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la création des arrêts: $e');
    }
  }

  // Supprimer tous les arrêts d'un itinéraire
  Future<void> deleteAllStopsForRoute(String routeId) async {
    try {
      await _supabaseClient
          .from('route_stops')
          .delete()
          .eq('route_id', routeId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression des arrêts: $e');
    }
  }

  // Mettre à jour l'ordre des arrêts
  Future<void> reorderStops(String routeId, List<String> stopIds) async {
    try {
      // Créer une liste de mises à jour à exécuter en parallèle
      final futures = <Future>[];
      
      for (int i = 0; i < stopIds.length; i++) {
        final future = _supabaseClient
            .from('route_stops')
            .update({'stop_order': i + 1})
            .eq('id', stopIds[i])
            .eq('route_id', routeId);
        futures.add(future);
      }
      
      await Future.wait(futures);
    } catch (e) {
      throw Exception('Erreur lors de la réorganisation des arrêts: $e');
    }
  }
} 