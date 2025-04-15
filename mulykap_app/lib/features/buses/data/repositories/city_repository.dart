import 'package:mulykap_app/features/buses/domain/models/city_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CityRepository {
  final SupabaseClient _supabaseClient;

  CityRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Récupérer toutes les villes
  Future<List<CityModel>> getAllCities() async {
    try {
      final response = await _supabaseClient
          .from('cities')
          .select()
          .order('name', ascending: true);

      return response.map<CityModel>((city) => CityModel.fromJson(city)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des villes: $e');
    }
  }

  // Récupérer les villes principales (is_main = true)
  Future<List<CityModel>> getMainCities() async {
    try {
      final response = await _supabaseClient
          .from('cities')
          .select()
          .eq('is_main', true)
          .order('name', ascending: true);

      return response.map<CityModel>((city) => CityModel.fromJson(city)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des villes principales: $e');
    }
  }

  // Récupérer les villes par province
  Future<List<CityModel>> getCitiesByProvince(String province) async {
    try {
      final response = await _supabaseClient
          .from('cities')
          .select()
          .eq('province', province)
          .order('name', ascending: true);

      return response.map<CityModel>((city) => CityModel.fromJson(city)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des villes par province: $e');
    }
  }

  // Récupérer une ville par son identifiant
  Future<CityModel> getCityById(String id) async {
    try {
      final response = await _supabaseClient
          .from('cities')
          .select()
          .eq('id', id)
          .single();

      return CityModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la ville: $e');
    }
  }

  // Créer une nouvelle ville
  Future<CityModel> createCity(CityModel city) async {
    try {
      final response = await _supabaseClient
          .from('cities')
          .insert(city.toJson())
          .select()
          .single();

      return CityModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la ville: $e');
    }
  }

  // Mettre à jour une ville existante
  Future<CityModel> updateCity(CityModel city) async {
    try {
      final response = await _supabaseClient
          .from('cities')
          .update(city.toJson())
          .eq('id', city.id)
          .select()
          .single();

      return CityModel.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la ville: $e');
    }
  }

  // Supprimer une ville
  Future<void> deleteCity(String id) async {
    try {
      await _supabaseClient
          .from('cities')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la ville: $e');
    }
  }
} 