import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusRepository {
  final SupabaseClient _supabaseClient;

  BusRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Récupérer tous les bus
  Future<List<BusModel>> getAllBuses() async {
    try {
      final response = await _supabaseClient
          .from('buses')
          .select()
          .order('created_at', ascending: false);

      return response.map<BusModel>((bus) => BusModel.fromMap(bus)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bus: $e');
    }
  }

  // Récupérer les bus d'une agence spécifique
  Future<List<BusModel>> getBusesByAgency(String agencyId) async {
    try {
      final response = await _supabaseClient
          .from('buses')
          .select()
          .eq('agency_id', agencyId)
          .order('created_at', ascending: false);

      return response.map<BusModel>((bus) => BusModel.fromMap(bus)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bus par agence: $e');
    }
  }

  // Récupérer un bus par son identifiant
  Future<BusModel> getBusById(String id) async {
    try {
      final response = await _supabaseClient
          .from('buses')
          .select()
          .eq('id', id)
          .single();

      return BusModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du bus: $e');
    }
  }

  // Créer un nouveau bus
  Future<BusModel> createBus(BusModel bus) async {
    try {
      final response = await _supabaseClient
          .from('buses')
          .insert(bus.toMap())
          .select()
          .single();

      return BusModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création du bus: $e');
    }
  }

  // Mettre à jour un bus existant
  Future<BusModel> updateBus(BusModel bus) async {
    try {
      final response = await _supabaseClient
          .from('buses')
          .update(bus.toMap())
          .eq('id', bus.id)
          .select()
          .single();

      return BusModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du bus: $e');
    }
  }

  // Supprimer un bus
  Future<void> deleteBus(String id) async {
    try {
      await _supabaseClient
          .from('buses')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du bus: $e');
    }
  }
} 