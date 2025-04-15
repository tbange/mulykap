import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgencyRepository {
  final SupabaseClient _supabaseClient;

  AgencyRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Récupérer toutes les agences
  Future<List<AgencyModel>> getAllAgencies() async {
    try {
      final response = await _supabaseClient
          .from('agencies')
          .select()
          .order('name', ascending: true);

      return response.map<AgencyModel>((agency) => AgencyModel.fromMap(agency)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des agences: $e');
    }
  }

  // Récupérer les agences d'une ville spécifique
  Future<List<AgencyModel>> getAgenciesByCity(String cityId) async {
    try {
      final response = await _supabaseClient
          .from('agencies')
          .select()
          .eq('city_id', cityId)
          .order('name', ascending: true);

      return response.map<AgencyModel>((agency) => AgencyModel.fromMap(agency)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des agences par ville: $e');
    }
  }

  // Récupérer une agence par son identifiant
  Future<AgencyModel> getAgencyById(String id) async {
    try {
      final response = await _supabaseClient
          .from('agencies')
          .select()
          .eq('id', id)
          .single();

      return AgencyModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'agence: $e');
    }
  }

  // Créer une nouvelle agence
  Future<AgencyModel> createAgency(AgencyModel agency) async {
    try {
      final response = await _supabaseClient
          .from('agencies')
          .insert(agency.toMap())
          .select()
          .single();

      return AgencyModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'agence: $e');
    }
  }

  // Mettre à jour une agence existante
  Future<AgencyModel> updateAgency(AgencyModel agency) async {
    try {
      final response = await _supabaseClient
          .from('agencies')
          .update(agency.toMap())
          .eq('id', agency.id)
          .select()
          .single();

      return AgencyModel.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'agence: $e');
    }
  }

  // Supprimer une agence
  Future<void> deleteAgency(String id) async {
    try {
      await _supabaseClient
          .from('agencies')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'agence: $e');
    }
  }
} 