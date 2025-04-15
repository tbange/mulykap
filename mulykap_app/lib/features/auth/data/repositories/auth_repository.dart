import 'package:mulykap_app/features/auth/domain/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepository {
  final supabase.GoTrueClient _auth;
  final supabase.SupabaseClient _client;

  AuthRepository({supabase.GoTrueClient? auth, supabase.SupabaseClient? client}) 
      : _auth = auth ?? supabase.Supabase.instance.client.auth,
        _client = client ?? supabase.Supabase.instance.client;

  Stream<supabase.AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<UserModel> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return UserModel.empty;
      }
      
      // Récupérer des informations supplémentaires depuis la table user_profiles
      final profileResponse = await _client
          .from('user_profiles')
          .select('first_name, last_name, phone, status')
          .eq('user_id', user.id)
          .single();
          
      // Récupérer le rôle de l'utilisateur
      final roleResponse = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .single();
          
      return UserModel(
        id: user.id,
        email: user.email,
        name: user.userMetadata?['name'] as String?,
        firstName: profileResponse['first_name'] as String?,
        lastName: profileResponse['last_name'] as String?,
        phone: profileResponse['phone'] as String?,
        status: profileResponse['status'] as String?,
        role: roleResponse['role'] as String?,
        createdAt: user.createdAt != null ? DateTime.parse(user.createdAt!) : null,
      );
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return UserModel.empty;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
    required String firstName,
    required String lastName,
    required String phone,
    required String userRole,
  }) async {
    try {
      print('Tentative d\'inscription pour: $email avec rôle: $userRole');
      
      // Étape 1: Créer l'utilisateur dans auth.users
      final response = await _auth.signUp(
        email: email,
        password: password,
      );
      
      print('Création utilisateur dans auth: ${response.user?.id}');
      
      if (response.user != null) {
        final userId = response.user!.id;
        
        try {
          // Étape 2: Créer le profil utilisateur
          print('Création profil utilisateur dans user_profiles...');
          await _client
              .from('user_profiles')
              .insert({
                'user_id': userId,
                'first_name': firstName,
                'last_name': lastName,
                'phone': phone,
                'status': 'active'
              })
              .select();
          
          // Étape 3: Créer le rôle utilisateur
          print('Création rôle utilisateur dans user_roles...');
          await _client
              .from('user_roles')
              .insert({
                'user_id': userId,
                'role': userRole
              })
              .select();
          
          // Étape 4: Connexion automatique seulement si tout est réussi
          await _auth.signInWithPassword(
            email: email,
            password: password,
          );
          print('Inscription et connexion réussies');
        } catch (e) {
          print('Erreur lors de la création du profil/rôle: $e');
          // Supprimer l'utilisateur auth si la création du profil/rôle échoue
          await _auth.admin.deleteUser(userId);
          throw Exception('Échec de la création du profil: $e');
        }
      } else {
        throw Exception('Échec de la création de l\'utilisateur');
      }
    } catch (e) {
      print('Erreur d\'inscription: $e');
      throw Exception('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation du mot de passe: ${e.toString()}');
    }
  }

  Future<void> updatePassword({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      await _auth.updateUser(
        supabase.UserAttributes(
          password: password,
        ),
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du mot de passe: ${e.toString()}');
    }
  }
} 