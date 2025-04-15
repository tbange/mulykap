import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConstants {
  // Récupérer les valeurs à partir du fichier .env
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
} 